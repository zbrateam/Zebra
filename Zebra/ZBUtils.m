//
//  ZBUtils.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 30/4/2563 BE.
//  Copyright © 2563 Wilson Styres. All rights reserved.
//

#import "ZBUtils.h"

@implementation ZBUtils

+ (NSString *)decodeCString:(const char *)cString fallback:(NSString *)fallback {
    return cString != 0 ? ([NSString stringWithUTF8String:cString] ?: [NSString stringWithCString:cString encoding:NSASCIIStringEncoding]) : (fallback ?: NSLocalizedString(@"Unknown", @""));
}

@end
