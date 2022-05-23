//
//  NSURLSession+Zebra.m
//  Zebra
//
//  Created by Adam Demasi on 21/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "NSURLSession+Zebra.h"
#import "ZBDevice.h"

@implementation NSURLSession (Zebra)

+ (instancetype)zbra_standardSession {
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [[NSURLSessionConfiguration ephemeralSessionConfiguration] mutableCopy];
        // Disable setting or storing cookies. Requests made via zbra_standardSession shouldn’t be
        // using cookies.
        configuration.HTTPCookieStorage = nil;
        configuration.HTTPAdditionalHeaders = @{
            @"User-Agent": [ZBDevice userAgent]
        };
        if (@available(iOS 13, *)) {
            configuration.TLSMinimumSupportedProtocolVersion = tls_protocol_version_TLSv12;
        } else {
            configuration.TLSMinimumSupportedProtocol = kTLSProtocol12;
        }
        session = [NSURLSession sessionWithConfiguration:configuration];
    });
    return session;
}

+ (instancetype)zbra_downloadSession {
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [[NSURLSessionConfiguration defaultSessionConfiguration] mutableCopy];
        configuration.HTTPMaximumConnectionsPerHost = 8;
        configuration.HTTPAdditionalHeaders = @{
            @"User-Agent": [ZBDevice downloadUserAgent],
            @"X-Firmware": [UIDevice currentDevice].systemVersion,
            @"X-Machine": [ZBDevice machineID],
            @"X-Unique-ID": [ZBDevice UDID],
            @"X-Cydia-ID": [ZBDevice UDID]
        };
        if (@available(iOS 13, *)) {
            configuration.TLSMinimumSupportedProtocolVersion = tls_protocol_version_TLSv10;
        } else {
            configuration.TLSMinimumSupportedProtocol = kTLSProtocol1;
        }
        session = [NSURLSession sessionWithConfiguration:configuration];
    });
    return session;
}

@end
