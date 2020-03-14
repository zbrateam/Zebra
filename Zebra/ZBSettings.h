//
//  ZBSettings.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 31/8/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBSource;

#import <Foundation/Foundation.h>

#pragma mark - Settings Keys

//Old settings keys
#define oledModeKey @"oledMode"
#define tintSelectionKey @"tintSelection"
#define thirteenModeKey @"thirteenMode"
#define randomFeaturedKey @"randomFeatured"
#define wantsFeaturedKey @"wantsFeatured"
#define wantsNewsKey @"wantsNews"
#define liveSearchKey @"liveSearch"
#define iconActionKey @"packageIconAction"
#define wishListKey @"wishList"
#define darkModeKey @"darkMode"
#define finishAutomaticallyKey @"finishAutomatically"

//New settings keys
extern NSString * _Nonnull const AccentColorKey;
extern NSString * _Nonnull const UseSystemAppearanceKey;
extern NSString * _Nonnull const InterfaceStyleKey;
extern NSString * _Nonnull const PureBlackModeKey;

#pragma mark - Accent Colors

typedef enum : NSUInteger {
    ZBAccentColorAquaVelvet,
    ZBAccentColorCornflowerBlue,
    ZBAccentColorGoldenTainoi,
    ZBAccentColorIrisBlue,
    ZBAccentColorLotusPink,
    ZBAccentColorMonochrome,
    ZBAccentColorMountainMeadow,
    ZBAccentColorPastelRed,
    ZBAccentColorPurpleHeart,
    ZBAccentColorRoyalBlue,
    ZBAccentColorShark,
    ZBAccentColorStorm,
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

+ (BOOL)usesSystemAccentColor;
+ (void)setUsesSystemAccentColor:(BOOL)usesSystemAccentColor;

+ (ZBInterfaceStyle)interfaceStyle;
+ (void)setInterfaceStyle:(ZBInterfaceStyle)style;

+ (BOOL)usesSystemAppearance;
+ (void)setUsesSystemAppearance:(BOOL)usesSystemAppearance;

+ (BOOL)pureBlackMode;
+ (void)setPureBlackMode:(BOOL)pureBlackMode;

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

+ (BOOL)isSectionFiltered:(NSString *)section forSource:(ZBSource *)source;

+ (void)setSection:(NSString *)section filtered:(BOOL)filtered forSource:(ZBSource *)source;

@end

NS_ASSUME_NONNULL_END
