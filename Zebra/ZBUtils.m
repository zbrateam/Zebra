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

+ (NSArray *)splitNameAndEmail:(NSString *)string {
    NSArray *components = [string componentsSeparatedByString:@"<"];
    if (components.count == 2) {
        NSString *name = [components[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *author = [components[1] stringByReplacingOccurrencesOfString:@">" withString:@""];
        return @[name, author];
    } else if (components.count == 1) {
        NSString *name = [components[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        return @[name];
    } else {
        return NULL;
    }
}

@end
