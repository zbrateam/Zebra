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

@end
