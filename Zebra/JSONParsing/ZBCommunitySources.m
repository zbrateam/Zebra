//
//  ZBCommunitySources.m
//  Zebra
//
//  Created by Adam Demasi on 2/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import "ZBCommunitySources.h"

@implementation ZBCommunitySources

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"repos": ZBJSONArrayOf(@"repos", [ZBCommunitySource class])
        };
    }
    return properties;
}

- (BOOL)isValid {
    return _repos != nil;
}

@end

@implementation ZBCommunitySource

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"type": ZBJSONString(@"type"),
            @"name": ZBJSONString(@"name"),
            @"label": ZBJSONString(@"label"),
            @"url": ZBJSONString(@"url"),
            @"ext": ZBJSONString(@"ext"),
            @"icon": ZBJSONString(@"icon"),
            @"appVersion": ZBJSONString(@"appVersion")
        };
    }
    return properties;
}

@end
