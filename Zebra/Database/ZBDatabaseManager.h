//
//  ZBDatabaseManager.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@class ZBPackage;
@class ZBRepo;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBDatabaseManager : NSObject
- (void)fullImport;
- (void)partialImport:(void (^)(BOOL success))completion;
- (void)fullRemoteImport:(void (^)(BOOL success))completion;
- (void)fullLocalImport:(void (^)(BOOL success))completion;
- (void)partialRemoteImport:(void (^)(BOOL success))completion;
- (int)numberOfPackagesInRepo:(int)repoID;
- (NSArray <ZBPackage *> *)installedPackages;
- (NSArray <ZBPackage *> *)packagesFromRepo:(int)repoID numberOfPackages:(int)limit startingAt:(int)start;
- (NSArray <ZBRepo *> *)sources;
- (NSArray <ZBPackage *> *)searchForPackageName:(NSString *)name numberOfResults:(int)results;
- (void)deleteRepo:(ZBRepo *)repo;
- (void)updateEssentials:(void (^)(BOOL success))completion;
@end

NS_ASSUME_NONNULL_END
