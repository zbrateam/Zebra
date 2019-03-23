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

NS_ASSUME_NONNULL_BEGIN

@interface ZBDatabaseManager : NSObject {
    NSString *databasePath;
}
- (void)updateDatabaseUsingCaching:(BOOL)useCaching completion:(void (^)(BOOL success, NSError *error))completion;
- (void)importLocalPackages:(void (^)(BOOL success))completion;
- (NSArray <ZBPackage *> *)packagesWithUpdates;
- (int)numberOfPackagesInRepo:(int)repoID;
- (NSArray <ZBPackage *> *)installedPackages;
- (NSArray <ZBPackage *> *)packagesFromRepo:(int)repoID numberOfPackages:(int)limit startingAt:(int)start;
- (NSArray <ZBRepo *> *)sources;
- (NSArray <ZBPackage *> *)searchForPackageName:(NSString *)name numberOfResults:(int)results;
- (void)deleteRepo:(ZBRepo *)repo;
- (NSMutableArray *)cleanUpDuplicatePackages:(NSArray *)packageList;
- (void)saveIcon:(UIImage *)icon forRepo:(ZBRepo *)repo;
- (UIImage *)iconForRepo:(ZBRepo *)repo;
@end

NS_ASSUME_NONNULL_END
