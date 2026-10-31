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
#define randomFeaturedKey @"randomFeatured"
#define wantsFeaturedKey @"wantsFeatured"
#define wantsNewsKey @"wantsNews"
#define liveSearchKey @"liveSearch"
#define iconActionKey @"packageIconAction"
#define wishListKey @"wishList"
#define darkModeKey @"darkMode"
#define finishAutomaticallyKey @"finishAutomatically"
#define featuredBlacklistKey @"blackListedRepos"

#pragma mark - Accent Colors

typedef NS_ENUM(NSInteger, ZBAccentColor) {
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
};

#pragma mark - Interface Styles

typedef NS_ENUM(NSInteger, ZBInterfaceStyle) {
    ZBInterfaceStyleLight,
    ZBInterfaceStyleDark,
    ZBInterfaceStylePureBlack,
};

#pragma mark - Featured Type

typedef NS_ENUM(NSInteger, ZBFeaturedType) {
    ZBFeaturedTypeSource,
    ZBFeaturedTypeRandom,
};

#pragma mark - Swipe Action Style

typedef NS_ENUM(NSInteger, ZBSwipeActionStyle) {
    ZBSwipeActionStyleText,
    ZBSwipeActionStyleIcon,
};

#pragma mark - Package Sorting Style

typedef NS_ENUM(NSInteger, ZBSortingType) {
    ZBSortingTypeABC,
    ZBSortingTypeDate,
    ZBSortingTypeInstalledSize
};

#pragma mark - Error Reports

typedef NS_ENUM(NSInteger, ZBSendErrorReports) {
    ZBSendErrorReportsUnspecified = -1,
    ZBSendErrorReportsNo,
    ZBSendErrorReportsYes
};

#pragma mark - Canister

typedef NS_ENUM(NSInteger, ZBSendCanisterIngest) {
    ZBSendCanisterIngestUnspecified = -1,
    ZBSendCanisterIngestNo,
    ZBSendCanisterIngestYes
};

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SendErrorReportsKey;

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
+ (void)setSelectedLanguage:(NSString *_Nullable)languageCode;

#pragma mark - Filters

+ (NSArray *)filteredSections;
+ (void)setFilteredSections:(NSArray *)filteredSources;
+ (NSDictionary *)filteredSources;
+ (void)setFilteredSources:(NSDictionary *)filteredSources;

+ (BOOL)isSectionFiltered:(NSString *)section forSource:(ZBSource *)source;
+ (void)setSection:(NSString *)section filtered:(BOOL)filtered forSource:(ZBSource *)source;

+ (NSDictionary *)blockedAuthors;
+ (void)setBlockedAuthors:(NSDictionary *)blockedAuthors;
+ (BOOL)isAuthorBlocked:(NSString *)name email:(NSString *)name;

+ (BOOL)filterIncompatibleArchitectures;
+ (void)setFilterIncompatibleArchitectures:(BOOL)filterIncompatibleArchitectures;

+ (BOOL)isPackageFiltered:(ZBPackage *)package;

#pragma mark - Homepage settings

+ (BOOL)wantsFeaturedPackages;
+ (void)setWantsFeaturedPackages:(BOOL)wantsFeaturedPackages;

+ (ZBFeaturedType)featuredPackagesType;
+ (void)setFeaturedPackagesType:(NSNumber *)featuredPackagesType;

+ (NSArray *)sourceBlacklist;
+ (void)setSourceBlacklist:(NSArray *)blacklist;

#pragma mark - Sources Settings

+ (BOOL)wantsAutoRefresh;
+ (void)setWantsAutoRefresh:(BOOL)autoRefresh;

+ (NSInteger)sourceRefreshTimeoutIndex;
+ (NSTimeInterval)sourceRefreshTimeout;
+ (void)setSourceRefreshTimeout:(NSNumber *)time;

#pragma mark - Changes Settings

+ (BOOL)wantsCommunityNews;
+ (void)setWantsCommunityNews:(BOOL)wantsCommunityNews;

#pragma mark - Packages Settings

+ (BOOL)alwaysInstallLatest;
+ (void)setAlwaysInstallLatest:(BOOL)alwaysInstallLatest;

#pragma mark - Search Settings

+ (BOOL)wantsLiveSearch;
+ (void)setWantsLiveSearch:(BOOL)liveSearch;

#pragma mark - Console Settings

+ (BOOL)wantsFinishAutomatically;
+ (void)setWantsFinishAutomatically:(BOOL)finishAutomatically;

#pragma mark - Swipe Action Settings

+ (ZBSwipeActionStyle)swipeActionStyle;
+ (void)setSwipeActionStyle:(NSNumber *)style;

#pragma mark - Wishlist

+ (NSArray *)wishlist;
+ (void)setWishlist:(NSArray *)wishlist;

#pragma mark - Package Sorting Type

+ (ZBSortingType)packageSortingType;
+ (void)setPackageSortingType:(ZBSortingType)sortingType;

#pragma mark - Error Reports

+ (ZBSendErrorReports)sendErrorReports;
+ (void)setSendErrorReports:(NSNumber *)sendErrorReports;

#pragma mark - Canister

+ (ZBSendCanisterIngest)sendCanisterIngest;
+ (void)setSendCanisterIngest:(NSNumber *)sendCanisterIngest;

+ (NSString *)canisterUpdateDate;
+ (void)setCanisterUpdateDate:(NSString *)canisterUpdateDate;

@end

NS_ASSUME_NONNULL_END
