//
//  ZBSettings.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 31/8/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBSource;
@class ZBPackage;

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
extern NSString * _Nonnull const AccentColorKey; // Stored as ZBAccentColor
extern NSString * _Nonnull const UseSystemAppearanceKey; // Stored as BOOL
extern NSString * _Nonnull const InterfaceStyleKey; // Stored as ZBInterfaceStyle
extern NSString * _Nonnull const PureBlackModeKey; // Stored as BOOL
extern NSString * _Nonnull const UsesSystemAccentColorKey; // Stored as BOOL

extern NSString * _Nonnull const UseSystemLanguageKey; // Stored as BOOL
extern NSString * _Nonnull const SelectedLanguageKey; // Stored as NSString

extern NSString * _Nonnull const FilteredSourcesKey; // Stored as NSDictionary
extern NSString * _Nonnull const FilteredSectionsKey; // Stored as NSArray
extern NSString * _Nonnull const BlockedAuthorsKey; // Stored as NSArray

extern NSString * _Nonnull const WantsFeaturedPackagesKey; // Stored as BOOL
extern NSString * _Nonnull const FeaturedPackagesTypeKey; // Stored as ZBFeaturedType

extern NSString * _Nonnull const SwipeActionStyleKey; // Stored as NSInteger

extern NSString * _Nonnull const WishlistKey; // Stored as NSArray

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

#pragma mark - Interface Styles

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

#pragma mark - Swipe Action Style

typedef enum : NSUInteger {
    ZBSwipeActionStyleText,
    ZBSwipeActionStyleIcon,
} ZBSwipeActionStyle;

NS_ASSUME_NONNULL_BEGIN

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

#pragma mark - Language

+ (BOOL)usesSystemLanguage;
+ (void)setUsesSystemLanguage:(BOOL)usesSystemLanguage;

+ (NSString *)selectedLanguage;
+ (void)setSelectedLanguage:(NSString *)languageCode;

#pragma mark - Filters

+ (NSArray *)filteredSections;
+ (void)setFilteredSections:(NSArray *)filteredSources;

+ (NSDictionary *)filteredSources;
+ (void)setFilteredSources:(NSDictionary *)filteredSources;

+ (BOOL)isSectionFiltered:(NSString *)section forSource:(ZBSource *)source;
+ (void)setSection:(NSString *)section filtered:(BOOL)filtered forSource:(ZBSource *)source;

+ (NSArray *)blockedAuthors;
+ (void)setBlockedAuthors:(NSArray *)blockedAuthors;
+ (BOOL)isAuthorBlocked:(NSString *)author;

+ (BOOL)isPackageFiltered:(ZBPackage *)package;

#pragma mark - Homepage settings

+ (BOOL)wantsFeaturedPackages;
+ (void)setWantsFeaturedPackages:(BOOL)wantsFeaturedPackages;

+ (ZBFeaturedType)featuredPackagesType;
+ (void)setFeaturedPackagesType:(NSNumber *)featuredPackagesType;

+ (NSArray *)sourceBlacklist;

#pragma mark - Changes Settings

+ (BOOL)wantsCommunityNews;
+ (void)setWantsCommunityNews:(BOOL)wantsCommunityNews;

#pragma mark - Search Settings

+ (BOOL)liveSearch;

#pragma mark - Swipe Action Settings

+ (ZBSwipeActionStyle)swipeActionStyle;
+ (void)setSwipeActionStyle:(NSNumber *)style;

#pragma mark - Wishlist

+ (NSArray *)wishlist;
+ (void)setWishlist:(NSArray *)wishlist;

@end

NS_ASSUME_NONNULL_END
