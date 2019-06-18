//
//  ZBDeviceHelper.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBDeviceHelper.h"
#import "MobileGestalt.h"
#import <UIKit/UIDevice.h>
#import <NSTask.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>

@implementation ZBDeviceHelper

+ (NSString *)UDID {
    CFStringRef udidCF = (CFStringRef)MGCopyAnswer(kMGUniqueDeviceID);
    NSString *udid = (__bridge NSString *)udidCF;
    if (udid == NULL) {
        // send a fake UDID in case this is a simulator
        udid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    return udid;
}

+ (NSString *)deviceModelID {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (NSString *)machineID {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *answer = malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *machineIdentifier = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    return machineIdentifier;
}

+ (void)sbreload {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/sbreload"];
    [task launch];
    [task waitUntilExit];
    
    if ([task terminationStatus] != 0) {
        NSLog(@"[Zebra] SBReload Failed. Trying to restart backboardd");
        //Ideally, this is only if sbreload fails
        [task setLaunchPath:@"/usr/libexec/zebra/supersling"];
        [task setArguments:@[@"/bin/launchctl", @"stop", @"com.apple.backboardd"]];
        
        [task launch];
    }
}

+ (void)uicache:(NSArray *)arguments observer:(NSObject <ZBConsoleCommandDelegate> *)observer {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/libexec/zebra/supersling"];
    [task setArguments:[@[@"/usr/bin/uicache"] arrayByAddingObjectsFromArray:arguments]];
    
    if (observer) {
        NSPipe *outputPipe = [[NSPipe alloc] init];
        NSFileHandle *output = [outputPipe fileHandleForReading];
        [output waitForDataInBackgroundAndNotify];
        [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:output];
        NSPipe *errorPipe = [[NSPipe alloc] init];
        NSFileHandle *error = [errorPipe fileHandleForReading];
        [error waitForDataInBackgroundAndNotify];
        [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(receivedErrorData:) name:NSFileHandleDataAvailableNotification object:error];
        [task setStandardOutput:outputPipe];
        [task setStandardError:errorPipe];
    }
    
    [task launch];
    [task waitUntilExit];
}

@end
