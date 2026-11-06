//
//  ZBGitHubRelease.m
//  Zebra
//
//  Created by Adam Demasi on 2/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import "ZBGitHubRelease.h"

@implementation ZBGitHubRelease

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"tag_name": ZBJSONString(@"tagName"),
            @"name": ZBJSONString(@"name"),
            @"body_html": ZBJSONString(@"bodyHTML"),
            @"prerelease": ZBJSONNumber(@"prerelease")
        };
    }
    return properties;
}

- (BOOL)isValid {
    return _tagName && _name && _bodyHTML;
}

@end
