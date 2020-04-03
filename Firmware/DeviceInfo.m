#import "DeviceInfo.h"

@implementation DeviceInfo {
    struct utsname _systemInfo;
    NSString *_model;
}

+ (instancetype)sharedInstance {
    static DeviceInfo *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DeviceInfo alloc] init];
        [sharedInstance initCpuArchitecture];
        uname(&(sharedInstance->_systemInfo));
        [sharedInstance initModel];
    });
    return sharedInstance;
}

- (void)initCpuArchitecture {
    cpu_type_t type;
    size_t size = sizeof(type);

    NXArchInfo const *ai;
    char *cpu = NULL;
    if (sysctlbyname("hw.cputype", &type, &size, NULL, 0) == 0 && (ai = NXGetArchInfoFromCpuType(type, CPU_SUBTYPE_MULTIPLE)) != NULL)
        cpu = (char *)ai->name;

    self->_cpuArchitecture = [NSString stringWithCString:cpu encoding:NSUTF8StringEncoding];

    NXFreeArchInfo(ai);

    self->_ios = (type == CPU_TYPE_ARM || type == CPU_TYPE_ARM64);
}


- (void)initModel {
    if (self->_ios) {
        self->_model = [NSString stringWithCString:self->_systemInfo.machine encoding:NSUTF8StringEncoding];
    } else {
        size_t size;
        char *cModel;

        sysctlbyname("hw.model", NULL, &size, NULL, 0);
        cModel = malloc(size);
        sysctlbyname("hw.model", cModel, &size, NULL, 0);

        self->_model = [NSString stringWithCString:cModel encoding:NSUTF8StringEncoding];
        free(cModel);
    }
}

- (NSRegularExpression *)regexWithPattern:(NSString *)pattern {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];

    if (!regex) {
        NSLog(@"Error parsing regex: '%@'", pattern);
        NSLog(@"Error: %@", error);
        exit(1);
    }

    return regex;
}

- (NSString *)getOperatingSystemVersion {
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSMutableString *versionString = [NSMutableString stringWithFormat:@"%d.%d", (int)version.majorVersion, (int)version.minorVersion];
    if (version.patchVersion != 0) {
        [versionString appendFormat:@".%d", (int)version.patchVersion];
    }
    return (NSString *)versionString;
}

- (NSString *)getModelName {
    NSRegularExpression *nameRegex = [self regexWithPattern:@"([A-Za-z]+)"];

    NSRange match = [nameRegex firstMatchInString:self->_model options:0 range:NSMakeRange(0, [self->_model length])].range;

    return [[self->_model substringWithRange:match] lowercaseString];
}

- (NSString *)getModelVersion {
    NSRegularExpression *versionRegex = [self regexWithPattern:@"([0-9]+,[0-9]+)"];

    NSRange match = [versionRegex firstMatchInString:self->_model options:0 range:NSMakeRange(0, [self->_model length])].range;

    return [[self->_model substringWithRange:match] stringByReplacingOccurrencesOfString:@"," withString:@"."];
}

- (NSString *)getDebianArchitecture {
    if (self->_ios) {
        return @"iphoneos-arm";
    } else {
        return @"cydia";
    }
}

- (NSString *)getOperatingSystem {
    if (self->_ios) {
        return @"ios";
    } else {
        return @"macosx";
    }
}

- (NSString *)getDPKGDataDirectory {
    if (self->_ios) {
        return @"/var/lib/dpkg";
    } else {
        return @"/Library/Cydia/dpkg";
    }
}

- (NSDictionary *)getCapabilities {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/gssc"];

    NSPipe *outPipe = [NSPipe pipe];
    [task setStandardOutput:outPipe];

    [task launch];
    [task waitUntilExit];

    NSData *gsscData = [[outPipe fileHandleForReading] readDataToEndOfFile];

    NSError *error;
    NSDictionary *unfilteredCapabilities = [NSPropertyListSerialization propertyListWithData:gsscData options:NSPropertyListMutableContainersAndLeaves format:nil error:&error];

    if (!unfilteredCapabilities) {
        NSLog(@"Error parsing device capabilites from GSSC");
        NSLog(@"Error: %@", error);
        exit(1);
    }

    NSRegularExpression *numberRegex = [self regexWithPattern:@"^[0-9]+$"];
    NSRegularExpression *uppercaseRegex = [self regexWithPattern:@"([A-Z])"];

    NSMutableDictionary *capabilities = [[NSMutableDictionary alloc] init];

    for (NSString *name in unfilteredCapabilities) {
        id value = [unfilteredCapabilities valueForKey:name];

        if ([value isKindOfClass:[NSString class]]
            && ![(NSString *)value isEqual:@"0"]
            && [numberRegex firstMatchInString:value options:0 range:NSMakeRange(0, [value length])]) {

            NSString *modifiedName = [[uppercaseRegex stringByReplacingMatchesInString:name
                                                                              options:0
                                                                                range:NSMakeRange(0, [name length])
                                                                         withTemplate:@"-$1"]
                                     lowercaseString];

            if ([modifiedName hasPrefix:@"-"]) {
                [capabilities setObject:value forKey:[modifiedName substringFromIndex:1]];
            } else {
                [capabilities setObject:value forKey:modifiedName];
            }
        }
    }
    
    return (NSDictionary *)capabilities;
}

- (NSString *)getCoreFoundationVersion {
    return [NSString stringWithFormat:@"%.2f", kCFCoreFoundationVersionNumber];
}

- (NSString *)getOperatingSystemType {
    return [[NSString stringWithCString:self->_systemInfo.sysname encoding:NSUTF8StringEncoding] lowercaseString];
}

- (NSString *)getOperatingSystemRelease {
    return [NSString stringWithCString:self->_systemInfo.release encoding:NSUTF8StringEncoding];
}

@end
