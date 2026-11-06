//
//  ZBPaymentVendorResponses.m
//  Zebra
//
//  Created by Adam Demasi on 2/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import "ZBPaymentVendorResponses.h"

@implementation ZBPurchaseResponse

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"status": ZBJSONNumber(@"status"),
            @"error": ZBJSONString(@"error"),
            @"url": ZBJSONString(@"url")
        };
    }
    return properties;
}

@end

@implementation ZBDownloadAuthorizationResponse

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"url": ZBJSONString(@"url")
        };
    }
    return properties;
}

@end
