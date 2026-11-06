//
//  ZBFeaturedBanners.m
//  Zebra
//
//  Created by Adam Demasi on 2/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import "ZBFeaturedBanners.h"

@implementation ZBFeaturedBanners

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"banners": ZBJSONArrayOf(@"banners", [ZBFeaturedBanner class]),
            @"itemSize": ZBJSONString(@"itemSize")
        };
    }
    return properties;
}

- (BOOL)isValid {
    return _banners != nil;
}

@end

@implementation ZBFeaturedBanner

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"url": ZBJSONString(@"url"),
            @"package": ZBJSONString(@"package"),
            @"title": ZBJSONString(@"title"),
            @"section": ZBJSONString(@"section")
        };
    }
    return properties;
}

- (BOOL)isValid {
    return _url || _package || _title;
}

- (NSDictionary <NSString *, NSString *> *)JSONDictionary {
    NSMutableDictionary <NSString *, NSString *> *dict = [NSMutableDictionary dictionary];
    dict[@"url"] = _url;
    dict[@"package"] = _package;
    dict[@"title"] = _title;
    dict[@"section"] = _section;
    return dict;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[ZBFeaturedBanner class]]) {
        return NO;
    }
    return [self.JSONDictionary isEqualToDictionary:[object JSONDictionary]];
}

- (NSUInteger)hash {
    return _url.hash ^ _package.hash ^ _title.hash ^ _section.hash;
}

@end
