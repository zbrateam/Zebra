//
//  ZBFeaturedBanners.h
//  Zebra
//
//  Created by Adam Demasi on 2/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBJSONObject.h"

@class ZBFeaturedBanner;

NS_ASSUME_NONNULL_BEGIN

@interface ZBFeaturedBanners : ZBJSONObject

@property (nonatomic, copy) NSArray <ZBFeaturedBanner *> *banners;
@property (nonatomic, copy, nullable) NSString *itemSize;

@end

@interface ZBFeaturedBanner : ZBJSONObject

@property (nonatomic, copy, nullable) NSString *url;
@property (nonatomic, copy, nullable) NSString *package;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *section;

- (NSDictionary <NSString *, NSString *> *)JSONDictionary;

@end

NS_ASSUME_NONNULL_END
