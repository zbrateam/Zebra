//
//  ZBSettings.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 31/8/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Settings Keys

#define oledModeKey @"oledMode"
#define tintSelectionKey @"tintSelection"
#define thirteenModeKey @"thirteenMode"
#define randomFeaturedKey @"randomFeatured"
#define wantsFeaturedKey @"wantsFeatured"
#define wantsNewsKey @"wantsNews"
#define liveSearchKey @"liveSearch"
#define iconActionKey @"packageIconAction"
#define wishListKey @"wishList"

#pragma mark - Accent Colors

typedef enum : NSUInteger {
    ZBAccentColorBlue,
    ZBAccentColorOrange,
    ZBAccentColorAdaptive,
} ZBAccentColor;

#pragma mark - Dark Mode Styles

typedef enum : NSUInteger {
    ZBInterfaceStyleLight,
    ZBInterfaceStyleDark,
    ZBInterfaceStylePureBlack,
} ZBInterfaceStyle;

#pragma mark - Featured Type

typedef enum : NSUInteger {
    ZBFeaturedTypeSource,
    ZBFeaturedTypeRandom,
} ZBFeaturedType;


NS_ASSUME_NONNULL_BEGIN

#pragma mark -

@interface ZBSettings : NSObject

#pragma mark - Theming

+ (ZBAccentColor)accentColor;
+ (void)setAccentColor:(ZBAccentColor)accentColor;

+ (ZBInterfaceStyle)style;
+ (void)setStyle:(ZBInterfaceStyle)style;

+ (NSString *_Nullable)appIconName;
+ (void)setAppIconName:(NSString *_Nullable)appIconName;

+ (BOOL)wantsFeaturedPackages;
+ (void)setWantsFeaturedPackages:(BOOL)wantsFeaturedPackages;

+ (ZBFeaturedType)featuredPackagesType;
+ (void)setFeaturedPackagesType:(ZBFeaturedType)featuredPackagesType;

+ (NSArray *)sourceBlacklist;

+ (BOOL)wantsCommunityNews;
+ (void)setWantsCommunityNews:(BOOL)wantsCommunityNews;

+ (BOOL)liveSearch;

@end

NS_ASSUME_NONNULL_END
