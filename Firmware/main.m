#import "Firmware.h"

#define FIRMWARE_VERSION 6

int main() {
    NSLog(@"[Zebra Firmware] full steam ahead");

    Firmware *firmware = [[Firmware alloc] init];
    [firmware loadInstalledPackages];

    DeviceInfo *device = [DeviceInfo sharedDevice];

    // generate device specific packages

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

    NSLog(@"[Zebra Firmware] my work here is done");
    return 0;
}
