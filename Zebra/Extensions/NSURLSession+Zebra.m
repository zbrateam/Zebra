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
        NSURLSessionConfiguration *configuration = [[NSURLSessionConfiguration ephemeralSessionConfiguration] copy];
        // Disable setting or storing cookies. Requests made via zbra_standardSession shouldn’t be
        // using cookies.
        #if TARGET_OS_IPHONE
        NSString *platform = @"iphoneos";
        #else
        NSString *platform = @"macos";
        #endif
        NSString *ua = [NSString stringWithFormat: @"Zebra;v=%@;t=client,%@;t=jailbreak,%@;t=distribution", @PACKAGE_VERSION, [ZBDevice jailbreakName], [ZBDevice bootstrapName]];
        configuration.HTTPCookieStorage = nil;
        configuration.HTTPAdditionalHeaders = @{
            @"User-Agent": [ZBDevice userAgent],
            @"Sec-CH-UA-Bitness": [NSString stringWithFormat:@"%lu", sizeof(void *) * 8],
            @"Sec-CH-UA-Platform": platform,
            @"Sec-CH-UA-Platform-Version": [[UIDevice currentDevice] systemVersion],
            @"Sec-CH-UA-Model": [ZBDevice machineID],
            @"Sec-CH-UA-Arch": [ZBDevice debianArchitecture],
            @"Sec-CH-UA": ua
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
        NSURLSessionConfiguration *configuration = [[NSURLSessionConfiguration defaultSessionConfiguration] copy];
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
