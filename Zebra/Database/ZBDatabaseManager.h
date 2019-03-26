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

NS_ASSUME_NONNULL_BEGIN

@interface ZBDatabaseManager : NSObject {
    NSString *databasePath;
}
- (void)updateDatabaseUsingCaching:(BOOL)useCaching completion:(void (^)(BOOL success, NSError *error))completion;
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
@end

NS_ASSUME_NONNULL_END
