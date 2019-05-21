//
//  NSString+UDID.m
//  Zebra
//
//  Created by Louis on 21/05/2019.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "MobileGestalt.h"
#import <UIKit/UIDevice.h>

@implementation NSString (UDID)

+ (NSString *) UDID {
    CFStringRef udidCF = (CFStringRef)MGCopyAnswer(kMGUniqueDeviceID);
    NSString *udid = (__bridge NSString *)udidCF;
    NSLog(@"%@", udid);
    
    if (udid == NULL) {
        // send a fake UDID in case this is a simulator
        udid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    return udid;
}

@end
