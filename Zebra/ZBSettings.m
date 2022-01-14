//
//  ZBSettings.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSettings.h"

@import UIKit.UIApplication;
@import UIKit.UIScreen;
@import UIKit.UIWindow;

@implementation ZBSettings

NSString *const UseSystemAppearanceKey = @"UseSystemAppearance";
NSString *const PureBlackModeKey = @"PureBlackMode";

NSString *const UseSystemLanguageKey = @"UseSystemLanguage";
NSString *const SelectedLanguageKey = @"AppleLanguages";

NSString *const FilteredSectionsKey = @"FilteredSections";
NSString *const FilteredSourcesKey = @"FilteredSources";
NSString *const BlockedAuthorsKey = @"BlockedAuthors";

NSString *const PackageFiltersKey = @"PackageFilters";
NSString *const SourceFilterKey = @"SourceFilter";

NSString *const WantsFeaturedPackagesKey = @"WantsFeaturedPackages";
NSString *const FeaturedPackagesTypeKey = @"FeaturedPackagesType";
NSString *const FeaturedSourceBlacklistKey = @"FeaturedSourceBlacklist";

NSString *const WantsAutoRefreshKey = @"AutoRefresh";
NSString *const SourceTimeoutKey = @"SourceTimeout";
NSString *const WantsInstalledPackagesCountKey = @"InstalledPackagesCount";

NSString *const WantsCommunityNewsKey = @"CommunityNews";

NSString *const AlwaysInstallLatestKey = @"AlwaysInstallLatest";
NSString *const RoleKey = @"Role";
NSString *const IgnoredUpdatesKey = @"IgnoredUpdates";

NSString *const WantsLiveSearchKey = @"LiveSearch";

NSString *const WantsFinishAutomaticallyKey = @"FinishAutomatically";

NSString *const SwipeActionStyleKey = @"SwipeActionStyle";

NSString *const FavoritesKey = @"Wishlist"; // Won't change the key value, too lazy to migrate wishlists

NSString *const PackageSortingTypeKey = @"PackageSortingType";

NSString *const AllowsCrashReportingKey = @"AllowsCrashReporting";

#pragma mark - Theming

+ (BOOL)pureBlackMode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:PureBlackModeKey]) {
        [self setPureBlackMode:NO];
        return NO;
    }
    return [defaults boolForKey:PureBlackModeKey];
}

+ (void)setPureBlackMode:(BOOL)pureBlackMode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:pureBlackMode forKey:PureBlackModeKey];
}

+ (NSString *_Nullable)appIconName {
    return [[UIApplication sharedApplication] alternateIconName];
}

+ (void)setAppIconName:(NSString *_Nullable)appIconName {
    
}

#pragma mark - Filters

+ (NSArray *)filteredSections {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return [defaults objectForKey:FilteredSectionsKey] ?: [NSArray new];
}

+ (void)setFilteredSections:(NSArray *)filteredSections {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:filteredSections forKey:FilteredSectionsKey];
}

+ (NSDictionary *)filteredSources {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return [defaults objectForKey:FilteredSourcesKey] ?: [NSDictionary new];
}

+ (void)setFilteredSources:(NSDictionary *)filteredSources {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:filteredSources forKey:FilteredSourcesKey];
}

+ (BOOL)isSectionFiltered:(NSString *)section forSource:(ZBSource *)source {
    return NO;
//    if (section == NULL) section = @"Uncategorized";
//
//    NSArray *filteredSections = [self filteredSections];
//    if ([filteredSections containsObject:section]) return YES;
//
//    NSDictionary *filteredSources = [self filteredSources];
//    NSArray *filteredSourceSections = [filteredSources objectForKey:[source uuid]];
//    if (!filteredSourceSections) return NO;
//
//    return [filteredSourceSections containsObject:section];
}

+ (void)setSection:(NSString *)section filtered:(BOOL)filtered forSource:(ZBSource *)source {
//    if (section == NULL) section = @"Uncategorized";
//    
//    NSMutableDictionary *filteredSources = [[self filteredSources] mutableCopy];
//    NSMutableArray *filteredSections = [[filteredSources objectForKey:[source uuid]] mutableCopy];
//    if (!filteredSections) filteredSections = [NSMutableArray new];
//    
//    if (filtered && ![filteredSections containsObject:section]) {
//        [filteredSections addObject:section];
//    }
//    else if (!filtered) {
//        [filteredSections removeObject:section];
//    }
//    
//    [filteredSources setObject:filteredSections forKey:[source uuid]];
//    [self setFilteredSources:filteredSources];
}

+ (NSDictionary *)blockedAuthors {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return [defaults objectForKey:BlockedAuthorsKey] ?: [NSDictionary new];
}

+ (void)setBlockedAuthors:(NSDictionary *)blockedAuthors {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:blockedAuthors forKey:BlockedAuthorsKey];
}

+ (BOOL)isAuthorBlocked:(NSString *)name email:(NSString *)email {
    NSArray *emails = [[self blockedAuthors] allKeys];
    NSArray *names = [[self blockedAuthors] allValues];
    return [emails containsObject:email] || [names containsObject:name];
}

+ (BOOL)isPackageFiltered:(ZBPackage *)package {
    //TODO: Package filters dont work
    return NO;
//    return [self isSectionFiltered:package.section forSource:package.source] || [self isAuthorBlocked:package.authorName email:package.authorEmail];
}

+ (ZBPackageFilter *)filterForSource:(ZBSource *)source section:(NSString *)section {
//    if (!source) return NULL;
//
//    NSDictionary *filters = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PackageFilters"];
//    NSDictionary *sectionFilters = filters[source.uuid];
//    if (sectionFilters) {
//        if (!section) section = source.uuid;
//        NSData *encodedFilter = sectionFilters[section];
//        if (encodedFilter.length) {
//            ZBPackageFilter *filter = [NSKeyedUnarchiver unarchiveObjectWithData:encodedFilter];
//            return filter;
//        }
//    }
    
    return NULL;
}

+ (void)setFilter:(ZBPackageFilter *)filter forSource:(ZBSource *)source section:(NSString *)section {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSMutableDictionary *filters = [[defaults dictionaryForKey:PackageFiltersKey] mutableCopy] ?: [NSMutableDictionary new];
//    NSMutableDictionary *sectionFilters = [filters[source.uuid] mutableCopy] ?: [NSMutableDictionary new];
//    
//    if (!section) section = source.uuid;
//    NSData *encodedFilter = [NSKeyedArchiver archivedDataWithRootObject:filter];
//    sectionFilters[section] = encodedFilter;
//    filters[source.uuid] = sectionFilters;
//    
//    [defaults setObject:filters forKey:PackageFiltersKey];
}

+ (ZBSourceFilter *)sourceFilter {
    NSData *encodedFilter = [[NSUserDefaults standardUserDefaults] dataForKey:SourceFilterKey];
    if (encodedFilter.length) {
        ZBSourceFilter *filter = [NSKeyedUnarchiver unarchiveObjectWithData:encodedFilter];
        return filter;
    }
    
    return NULL;
}

+ (void)setSourceFilter:(ZBSourceFilter *)filter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:filter] forKey:SourceFilterKey];
}

#pragma mark - Homepage Settings

+ (BOOL)wantsFeaturedPackages {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:WantsFeaturedPackagesKey]) {
        [self setWantsFeaturedPackages:YES];
        return YES;
    }
    return [defaults boolForKey:WantsFeaturedPackagesKey];
}

+ (void)setWantsFeaturedPackages:(BOOL)wantsFeaturedPackages {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:wantsFeaturedPackages forKey:WantsFeaturedPackagesKey];
}

+ (ZBFeaturedType)featuredPackagesType {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:FeaturedPackagesTypeKey]) {
        [self setFeaturedPackagesType:@(ZBFeaturedTypeSource)];
        return ZBFeaturedTypeSource;
    }
    return (ZBFeaturedType)[defaults integerForKey:FeaturedPackagesTypeKey];
}

+ (void)setFeaturedPackagesType:(NSNumber *)featuredPackagesType {
    ZBFeaturedType type = featuredPackagesType.intValue;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger:type forKey:FeaturedPackagesTypeKey];
}

+ (NSArray *)sourceBlacklist {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return [defaults arrayForKey:FeaturedSourceBlacklistKey] ?: [NSArray new];
}

+ (void)setSourceBlacklist:(NSArray *)blacklist {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:blacklist forKey:FeaturedSourceBlacklistKey];
}

#pragma mark - Sources Settings

+ (BOOL)wantsAutoRefresh {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:WantsAutoRefreshKey]) {
        [self setWantsAutoRefresh:YES];
        return YES;
    }
    return [defaults boolForKey:WantsAutoRefreshKey];
}

+ (void)setWantsAutoRefresh:(BOOL)autoRefresh {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:autoRefresh forKey:WantsAutoRefreshKey];
}

+ (NSInteger)sourceRefreshTimeoutIndex {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:SourceTimeoutKey]) {
        [self setSourceRefreshTimeout:@5];
        return 5;
    }
    return [defaults integerForKey:SourceTimeoutKey];
}

+ (NSTimeInterval)sourceRefreshTimeout {
    NSArray *choices = @[@5, @10, @15, @30, @45, @60];
    NSInteger index = [self sourceRefreshTimeoutIndex];
    if (index > [choices count]) return (NSTimeInterval)[[choices lastObject] doubleValue];
    
    return (NSTimeInterval)[[choices objectAtIndex:index] doubleValue];
}

+ (void)setSourceRefreshTimeout:(NSNumber *)time {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger:time.intValue forKey:SourceTimeoutKey];
}

+ (BOOL)wantsInstalledPackagesCount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (![defaults objectForKey:WantsInstalledPackagesCountKey]) {
        [self setWantsInstalledPackagesCount:NO];
        return NO;
    }
    return [defaults boolForKey:WantsInstalledPackagesCountKey];
}

+ (void)setWantsInstalledPackagesCount:(BOOL)wantsInstalledPackagesCount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setBool:wantsInstalledPackagesCount forKey:WantsInstalledPackagesCountKey];
}

#pragma mark - Changes Settings

+ (BOOL)wantsCommunityNews {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:WantsCommunityNewsKey]) {
        [self setWantsCommunityNews:YES];
        return YES;
    }
    return [defaults boolForKey:WantsCommunityNewsKey];
}

+ (void)setWantsCommunityNews:(BOOL)wantsCommunityNews {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:wantsCommunityNews forKey:WantsCommunityNewsKey];
}

#pragma mark - Packages Settings

+ (BOOL)alwaysInstallLatest {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:AlwaysInstallLatestKey]) {
        [self setAlwaysInstallLatest:YES];
        return YES;
    }
    return [defaults boolForKey:AlwaysInstallLatestKey];
}

+ (void)setAlwaysInstallLatest:(BOOL)alwaysInstallLatest {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:alwaysInstallLatest forKey:AlwaysInstallLatestKey];
}

+ (uint8_t)role {
#if ZB_DBEUG
    return 3;
#else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:RoleKey]) {
        [self setRole:@2];
        return 2;
    }
    return [defaults integerForKey:RoleKey];
#endif
}

+ (void)setRole:(NSNumber *)role {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger:role.unsignedIntValue forKey:RoleKey];
}

+ (NSArray *)ignoredUpdates {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:IgnoredUpdatesKey] ?: [NSArray new];
}

+ (BOOL)areUpdatesIgnoredForPackageIdentifier:(NSString *)identifier {
    return [[self ignoredUpdates] containsObject:identifier];
}

+ (void)setUpdatesIgnored:(BOOL)updatesIgnored forPackageIdentifier:(NSString *)identifier {
    NSMutableArray *ignoredUpdates = [[self ignoredUpdates] mutableCopy];
    BOOL areUpdatesIgnored = [ignoredUpdates containsObject:identifier];
    
    if (!updatesIgnored && areUpdatesIgnored) {
        [ignoredUpdates removeObject:identifier];
    } else if (updatesIgnored && !areUpdatesIgnored) {
        [ignoredUpdates addObject:identifier];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:ignoredUpdates forKey:IgnoredUpdatesKey];
}

//#pragma mark - Search Settings
//
//+ (BOOL)wantsLiveSearch {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    
//    if (![defaults objectForKey:WantsLiveSearchKey]) {
//        [self setWantsLiveSearch:YES];
//        return YES;
//    }
//    return [defaults boolForKey:WantsLiveSearchKey];
//}
//
//+ (void)setWantsLiveSearch:(BOOL)wantsLiveSearch {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    
//    [defaults setBool:wantsLiveSearch forKey:WantsLiveSearchKey];
//}

#pragma mark - Console Settings

+ (BOOL)wantsFinishAutomatically {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:WantsFinishAutomaticallyKey]) {
        [self setWantsFinishAutomatically:NO];
        return NO;
    }
    return [defaults boolForKey:WantsFinishAutomaticallyKey];
}

+ (void)setWantsFinishAutomatically:(BOOL)finishAutomatically {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:finishAutomatically forKey:WantsFinishAutomaticallyKey];
}

#pragma mark - Swipe Action Style

+ (ZBSwipeActionStyle)swipeActionStyle {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:SwipeActionStyleKey]) {
        [self setSwipeActionStyle:@(ZBSwipeActionStyleText)];
        return ZBSwipeActionStyleText;
    }
    return [defaults boolForKey:SwipeActionStyleKey];
}

+ (void)setSwipeActionStyle:(NSNumber *)newStyle {
    ZBSwipeActionStyle style = newStyle.intValue;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger:style forKey:SwipeActionStyleKey];
}

#pragma mark - Favorites

+ (NSArray *)favoritePackages {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return [defaults arrayForKey:FavoritesKey] ?: [NSArray new];
}

+ (void)setFavoritePackages:(NSArray *)favorites {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:favorites forKey:FavoritesKey];
}

#pragma mark - Package Sorting Type

+ (ZBSortingType)packageSortingType {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:PackageSortingTypeKey]) {
        [self setPackageSortingType:ZBSortingTypeABC];
        return ZBSortingTypeABC;
    }
    return [defaults integerForKey:PackageSortingTypeKey];
}

+ (void)setPackageSortingType:(ZBSortingType)sortingType {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger:sortingType forKey:PackageSortingTypeKey];
}

#pragma mark - Crash Reporting

+ (BOOL)allowsCrashReporting {
#if DEBUG
    return NO;
#else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:AllowsCrashReportingKey]) {
        [self setAllowsCrashReporting:YES];
        return YES;
    }
    return [defaults boolForKey:AllowsCrashReportingKey];
#endif
}

+ (void)setAllowsCrashReporting:(BOOL)crashReporting {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:crashReporting forKey:AllowsCrashReportingKey];
}

#pragma mark - Source Update

+ (NSDate *)lastSourceUpdate {
    NSDate *lastUpdatedDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:@"lastUpdatedDate"];
    return lastUpdatedDate ?: [NSDate distantPast];
}

+ (void)updateLastSourceUpdate {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastUpdatedDate"];
}

@end
