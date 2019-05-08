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
#import <ZBDatabaseDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBDatabaseManager : NSObject <ZBDownloadDelegate> {
    NSString *databasePath;
}
@property (nonatomic, weak) id <ZBDatabaseDelegate> databaseDelegate;
+ (id)sharedInstance;
+ (NSDate *)lastUpdated;
- (int)openDatabase;
- (int)closeDatabase;
- (BOOL)isDatabaseOpen;
- (void)updateDatabaseUsingCaching:(BOOL)useCaching requested:(BOOL)requested;
- (void)justImportLocal;
- (void)importLocalPackages;
- (int)numberOfPackagesInRepo:(ZBRepo *)repo;
- (NSArray <ZBPackage *> *)installedPackages;
- (NSArray <ZBPackage *> *)packagesFromRepo:(ZBRepo *)repo inSection:(NSString * _Nullable)section numberOfPackages:(int)limit startingAt:(int)start;
- (NSArray <ZBRepo *> *)sources;
- (NSArray <ZBPackage *> *)searchForPackageName:(NSString *)name numberOfResults:(int)results;
- (void)deleteRepo:(ZBRepo *)repo;
- (NSArray *)otherVersionsForPackage:(ZBPackage *)package;
- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList;
- (void)saveIcon:(UIImage *)icon forRepo:(ZBRepo *)repo;
- (UIImage *)iconForRepo:(ZBRepo *)repo;
- (NSDictionary *)sectionReadoutForRepo:(ZBRepo *)repo;
- (int)numberOfPackagesFromRepo:(ZBRepo *)repo inSection:(NSString *)section;
- (void)dropTables;
- (BOOL)packageIsInstalled:(ZBPackage *)package versionStrict:(BOOL)strict;
- (BOOL)packageIsAvailable:(ZBPackage *)package;
- (ZBPackage *)packageForID:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version;
- (BOOL)doesPackage:(ZBPackage *)package satisfyComparison:(NSString *)comparison ofVersion:(NSString *)version;
- (NSArray <ZBPackage *>*)packagesWithUpdates;
- (void)updateLastUpdated;
@end

NS_ASSUME_NONNULL_END
