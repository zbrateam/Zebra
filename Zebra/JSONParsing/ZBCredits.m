//
//  ZBCredits.m
//  Zebra
//
//  Created by Adam Demasi on 2/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import "ZBCredits.h"

@implementation ZBCredits

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"sections": ZBJSONArrayOf(@"sections", [ZBCreditsSection class])
        };
    }
    return properties;
}

- (BOOL)isValid {
    return _sections != nil;
}

@end

@implementation ZBCreditsSection

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"title": ZBJSONString(@"title"),
            @"items": ZBJSONArrayOf(@"items", [ZBCreditsItem class])
        };
    }
    return properties;
}

- (BOOL)isValid {
    return _title && _items;
}

@end

@implementation ZBCreditsItem

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"name": ZBJSONString(@"name"),
            @"subtitle": ZBJSONString(@"subtitle"),
            @"link": ZBJSONString(@"link")
        };
    }
    return properties;
}

@end
