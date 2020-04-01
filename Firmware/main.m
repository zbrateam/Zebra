#import "Firmware.h"

#define FIRMWARE_VERSION 6

@implementation Firmware {
    NSString *_dataDirectory;
    NSMutableString *_status;
    DeviceInfo *_deviceInfo;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self->_status = [[NSMutableString alloc] init];
        self->_deviceInfo = [DeviceInfo sharedInstance];
        self->_dataDirectory = [self->_deviceInfo getDPKGDataDirectory];
    }
    return self;
}

- (void)exitWithError:(NSError *)error andMessage:(NSString *)message {
    NSLog(@"%@", message);
    if (error) {
        NSLog(@"Error: %@", error);
    }
    exit(1);
}

- (void)loadInstalledPackages {

    // regex

    NSString *virtualFirmwarePattern = @"^Package: (firmware|gsc[.].+|cy[+].+)\n$";

    NSError *error;
    NSRegularExpression *virtualFirmwareRegex = [NSRegularExpression regularExpressionWithPattern:virtualFirmwarePattern options:0 error:&error];

    if (!virtualFirmwareRegex) {
        [self exitWithError:error andMessage:[NSString stringWithFormat:@"Error parsing regex: '%@'", virtualFirmwarePattern]];
    }

    // control variables

    BOOL virtualFirmwarePackage = NO;
    BOOL previousWasBlank = YES;

    // file reading

    const char *statusFilePath = [[self->_dataDirectory stringByAppendingString:@"/status"] UTF8String];
    FILE *statusFile;
    char *cLine = NULL;
    size_t len = 0;
    ssize_t read;

    statusFile = fopen(statusFilePath, "r");
    if (statusFile == NULL) {
        [self exitWithError:nil andMessage:[NSString stringWithFormat:@"Error opening statusfile for reading at: %s", statusFilePath]];
    }

    while ((read = getline(&cLine, &len, statusFile)) != -1) {
        if (strcmp("\n", cLine) == 0) {
            previousWasBlank = YES;

            if (virtualFirmwarePackage) {
                virtualFirmwarePackage = NO;
            } else {
                [self->_status appendString:[NSString stringWithCString:cLine encoding:NSUTF8StringEncoding]];
            }

            continue;
        }

        if (virtualFirmwarePackage) {
            continue;
        }

        NSString *line = [NSString stringWithCString:cLine encoding:NSUTF8StringEncoding];

        if (previousWasBlank) {
            previousWasBlank = NO;

            if (line.length == [virtualFirmwareRegex rangeOfFirstMatchInString:line options:0 range:NSMakeRange(0, line.length)].length) {
                virtualFirmwarePackage = YES;
                continue;
            }
        }

        [self->_status appendString:line];
    }
}

- (void)generatePackageListFile:(NSString *)package {
    static NSString *packageList;
    static NSString *pathFormat;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        packageList = @"/.\n";
        pathFormat = @"%@/info/%@.list";
    });

    NSString *packageListFile = [NSString stringWithFormat:pathFormat, self->_dataDirectory, package];

    NSError *error;
    if (![packageList writeToFile:packageListFile atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        [self exitWithError:error andMessage:[NSString stringWithFormat:@"Error writing package list to %@", packageListFile]];
    }
}

- (void)generatePackage:(NSString *)package forVersion:(NSString *)version withDescription:(NSString *)description {
    static NSString *packageTemplate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        packageTemplate = [NSString stringWithFormat:
                           @"Package: %%@\n"
                           "Essential: yes\n"
                           "Status: install ok installed\n"
                           "Priority: required\n"
                           "Section: System\n"
                           "Installed-Size: 0\n"
                           "Architecture: %@\n"
                           "Version: %%@\n"
                           "Description: %%@\n"
                           "Maintainer: Jay Freeman (saurik) <saurik@saurik.com>\n"
                           "Tag: role::cydia\n"
                           "\n",
                           [self->_deviceInfo getDebianArchitecture]];
    });

    // Create list file for package
    [self generatePackageListFile:package];

    // Add package to status
    [self->_status appendFormat:packageTemplate, package, version, description];
}

- (void)generatePackage:(NSString *)package forVersion:(NSString *)version withDescription:(NSString *)description andName:(NSString *)name {
    static NSString *packageTemplate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        packageTemplate = [NSString stringWithFormat:
                           @"Package: %%@\n"
                           "Essential: yes\n"
                           "Status: install ok installed\n"
                           "Priority: required\n"
                           "Section: System\n"
                           "Installed-Size: 0\n"
                           "Architecture: %@\n"
                           "Version: %%@\n"
                           "Description: %%@\n"
                           "Maintainer: Jay Freeman (saurik) <saurik@saurik.com>\n"
                           "Tag: role::cydia\n"
                           "Name: %%@\n"
                           "\n",
                           [self->_deviceInfo getDebianArchitecture]];
    });

    // Create list file for package
    [self generatePackageListFile:package];

    // Add package to status
    [self->_status appendFormat:packageTemplate, package, version, description, name];
}

- (void)generateCapabilityPackages {
    NSDictionary *capabilites = [self->_deviceInfo getCapabilities];

    // generate packages for device capabilites
    NSString *ipad = @"ipad";
    NSString *gsc = @"gsc.";
    NSString *standardDescription = @"virtual GraphicsServices dependency";

    for (NSString *name in capabilites) {
        NSString *packageVersion = [capabilites valueForKey:name];

        if ([ipad isEqualToString:name]) {
            [self generatePackage:@"gsc.ipad" forVersion:packageVersion withDescription:@"this device has a very large screen" andName:@"iPad"];
            [self generatePackage:@"gsc.wildcat" forVersion:packageVersion withDescription:@"this device has a very large screen" andName:@"iPad"];
        } else {
            [self generatePackage:[gsc stringByAppendingString:name] forVersion:packageVersion withDescription:standardDescription];
        }
    }
}

- (void)writePackagesToStatusFile {
    NSError *error;
    NSString *statusFile = [self->_dataDirectory stringByAppendingString:@"/status"];

    if (![self->_status writeToFile:statusFile atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        [self exitWithError:error andMessage:@"Error writing to statusfile"];
    }
}

- (void)setupUserSymbolicLink {

    // -------------
    // TODO: implement cp -afT in objective-c
    // -------------

    NSError *error;

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *userDirectory = @"/User";
    NSString *varMobileDirectory = @"/var/mobile";

    NSDictionary *userAttributes = [fileManager attributesOfItemAtPath:userDirectory error:nil];


    // copy files from /User to /var/mobile

    if (userAttributes && ![userAttributes.fileType isEqualToString:NSFileTypeSymbolicLink] && [userAttributes.fileType isEqualToString:NSFileTypeDirectory]) {
        pid_t pid;
        extern char **environ;
        char *argv[] = {
            "/bin/cp",
            "-afT",
            (char *)[userDirectory UTF8String],
            (char *)[varMobileDirectory UTF8String],
            NULL
        };

        posix_spawn(&pid, argv[0], NULL, NULL, argv, environ);
        waitpid(pid, NULL, 0);
    }


    // delete user directory

    if (![fileManager removeItemAtPath:userDirectory error:&error]) {
        [self exitWithError:error andMessage:[NSString stringWithFormat:@"Error deleting %@", userDirectory]];
    }

    // symlink user directory to mobile user directory

    if (![fileManager createSymbolicLinkAtPath:userDirectory withDestinationPath:varMobileDirectory error:&error]) {
        [self exitWithError:error andMessage:[NSString stringWithFormat:@"Error creating symbolic link at %@ to %@", userDirectory, varMobileDirectory]];
    }
}

@end


int main() {
    Firmware *firmware = [[Firmware alloc] init];

    [firmware loadInstalledPackages];
    DeviceInfo *device = [DeviceInfo sharedInstance];

    [firmware generateCapabilityPackages];


    // generate always needed packages

    NSString *iosVersion = [device getOperatingSystemVersion];

    if (device.ios) {
        [firmware generatePackage:@"firmware" forVersion:iosVersion withDescription:@"almost impressive Apple frameworks" andName:@"iOS Firmware"];
    }

    NSString *packageName = [@"cy+os." stringByAppendingString:[device getOperatingSystem]];
    [firmware generatePackage:packageName forVersion:iosVersion withDescription:@"virtual operating system dependency"];

    packageName = [@"cy+cpu." stringByAppendingString:device.cpuArchitecture];
    [firmware generatePackage:packageName forVersion:@"0" withDescription:@"virtual CPU dependency"];

    packageName = [@"cy+model." stringByAppendingString:[device getModelName]];
    [firmware generatePackage:packageName forVersion:[device getModelVersion] withDescription:@"virtual model dependency"];

    packageName = [@"cy+kernel." stringByAppendingString:[device getOperatingSystemType]];
    [firmware generatePackage:packageName forVersion:[device getOperatingSystemRelease] withDescription:@"virtual kernel dependency"];

    [firmware generatePackage:@"cy+lib.corefoundation" forVersion:[device getCoreFoundationVersion] withDescription:@"virtual corefoundation dependency"];


    [firmware writePackagesToStatusFile];

    if (device.ios) {
        [firmware setupUserSymbolicLink];

        // write firmware version

        NSError *error;

        NSString *firmwareFile = @"/var/lib/cydia/firmware.ver";
        NSString *firwareVersion = [NSString stringWithFormat:@"%d\n", FIRMWARE_VERSION];

        if (![firwareVersion writeToFile:firmwareFile atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            [firmware exitWithError:error andMessage:[NSString stringWithFormat:@"Error writing firmware version to %@", firmwareFile]];
        }
    }

    NSLog(@"my work here is done");
    return 0;
}
