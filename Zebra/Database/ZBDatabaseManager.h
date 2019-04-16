//
//  ZBDatabaseManager.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@class ZBPackage;
@class ZBRepo;
@class UIImage;

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <Downloads/ZBDownloadDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBDatabaseManager : NSObject <ZBDownloadDelegate> {
    NSString *databasePath;
}
- (void)updateDatabaseUsingCaching:(BOOL)useCaching;
- (void)importLocalPackages:(void (^)(BOOL success))completion;
- (NSArray <ZBPackage *> *)packagesWithUpdates;
- (int)numberOfPackagesInRepo:(ZBRepo *)repo;
- (NSArray <ZBPackage *> *)installedPackages;
- (NSArray <ZBPackage *> *)packagesFromRepo:(ZBRepo *)repo inSection:(NSString * _Nullable)section numberOfPackages:(int)limit startingAt:(int)start;
- (NSArray <ZBRepo *> *)sources;
- (NSArray <ZBPackage *> *)searchForPackageName:(NSString *)name numberOfResults:(int)results;
- (void)deleteRepo:(ZBRepo *)repo;
- (NSArray *)otherVersionsForPackage:(ZBPackage *)package inDatabase:(sqlite3 *)database;
- (NSMutableArray *)cleanUpDuplicatePackages:(NSArray *)packageList;
- (void)saveIcon:(UIImage *)icon forRepo:(ZBRepo *)repo;
- (UIImage *)iconForRepo:(ZBRepo *)repo;
- (BOOL)packageIDHasUpgrade:(NSString *)packageID;
- (NSArray <NSArray *> *)sectionReadoutForRepo:(ZBRepo *)repo;
- (int)numberOfPackagesFromRepo:(ZBRepo *)repo inSection:(NSString *)section;
- (void)dropTables;
- (BOOL)packageIsInstalled:(ZBPackage *)package inDatabase:(sqlite3 *)database;
- (BOOL)packageIsAvailable:(ZBPackage *)package inDatabase:(sqlite3 *)database;
- (ZBPackage *)packageForID:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version inDatabase:(sqlite3 *)database;
- (BOOL)doesPackage:(ZBPackage *)package satisfyComparison:(NSString *)comparison ofVersion:(NSString *)version;
- (ZBRepo *)repoMatchingRepoID:(int)repoID;
@end

NS_ASSUME_NONNULL_END
