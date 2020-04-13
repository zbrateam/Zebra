//
//  ZBQueue.h
//  Zebra
//
//  Created by Wilson Styres on 1/29/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class UIColor;
@class ZBPackage;

#import <Foundation/Foundation.h>
#import <Queue/ZBQueueType.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBQueue : NSObject
@property BOOL removingZebra;
@property (nonatomic, strong) NSString *zebraPath;
@property (nonatomic, strong) NSMutableArray<NSString *> *queuedPackagesList;
+ (id)sharedQueue;
+ (int)count;
+ (UIColor *)colorForQueueType:(ZBQueueType)queue;
- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue;
- (void)addPackages:(NSArray <ZBPackage *> *)packages toQueue:(ZBQueueType)queue;
- (void)addDependency:(ZBPackage *)package;
- (void)addConflict:(ZBPackage *)package;
- (void)removePackage:(ZBPackage *)package;
- (NSArray *)tasksToPerform;
- (NSMutableArray *)queueFromType:(ZBQueueType)queue;
- (NSArray<NSNumber *> *)actionsToPerform;
- (NSString *)displayableNameForQueueType:(ZBQueueType)queue;
- (int)numberOfPackagesInQueue:(ZBQueueType)queue;
- (BOOL)needsToDownloadPackages;
- (NSArray *)packagesToDownload;
- (BOOL)contains:(ZBPackage *)package inQueue:(ZBQueueType)queue;
- (NSArray <NSArray <ZBPackage *> *> *)topDownQueue;
- (NSString *)downloadSizeForQueue:(ZBQueueType)queueType;
- (BOOL)hasIssues;
- (NSArray <NSArray <NSString *> *> *)issues;
- (void)clear;
- (NSMutableArray *)dependencyQueue;
- (NSMutableArray *)conflictQueue;
- (NSMutableArray <NSString *> *)queuedPackagesList;
- (ZBQueueType)locate:(ZBPackage *)package;
- (BOOL)containsEssentialOrRequiredPackage;
- (void)addConflict:(ZBPackage *)package removeDependencies:(BOOL)remove;

- (NSArray <NSDictionary *> *)packagesQueuedForAdddition;
- (NSArray <NSDictionary *> *)installedPackagesListExcluding:(ZBPackage *_Nullable)exclude;
- (NSArray <NSDictionary *> *)virtualPackagesListExcluding:(ZBPackage *_Nullable)exclude;
- (NSArray <NSString *> *)packageIDsQueuedForRemoval;
@end

NS_ASSUME_NONNULL_END
