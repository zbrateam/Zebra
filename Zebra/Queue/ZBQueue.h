//
//  ZBQueue.h
//  Zebra
//
//  Created by Wilson Styres on 1/29/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBQueueType.h"
#import "ZBQueueViewController.h"

@class ZBPackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBQueue : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *managedQueue;
@property (nonatomic, strong) NSMutableArray<NSArray *> *failedDepQueue;
@property (nonatomic, strong) NSMutableArray<NSArray *> *failedConQueue;
+ (id)sharedInstance;
- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue;
- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue ignoreDependencies:(BOOL)ignore;
- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue replace:(ZBPackage *)oldPackage;
- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue requiredBy:(nullable ZBPackage *)requiredPackage;
- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue ignoreDependencies:(BOOL)ignore requiredBy:(nullable ZBPackage *)requiredPackage replace:(nullable ZBPackage *)oldPackage;
- (void)addPackages:(NSArray<ZBPackage *> *)packages toQueue:(ZBQueueType)queue;
- (void)markPackageAsFailed:(ZBPackage *)package forDependency:(NSString *)failedDependency;
- (void)markPackageAsFailed:(ZBPackage *)package forConflicts:(ZBPackage *)conflict conflictionType:(int)type;
- (void)removePackage:(ZBPackage *)package fromQueue:(ZBQueueType)queue;
- (NSArray *)tasks:(NSArray *)debs;
- (int)numberOfPackagesForQueue:(NSString *)queue;
- (nullable NSMutableArray <ZBPackage *> *)packagesRequiredBy:(ZBPackage *)package;
- (nullable ZBPackage *)packageReplacedBy:(ZBPackage *)package;
- (ZBPackage *)packageInQueue:(ZBQueueType)queue atIndex:(NSInteger)index;
- (void)clearQueue;
- (NSArray *)actionsToPerform;
- (NSMutableArray *)queueArray:(ZBQueueType)queue;
- (BOOL)hasObjects;
- (BOOL)containsPackage:(ZBPackage *)package;
- (BOOL)containsPackage:(ZBPackage *)package queue:(ZBQueueType)queue;
- (BOOL)containsPackageName:(NSString *)packageName queue:(ZBQueueType)queue;
- (NSArray *)packagesToDownload;
- (BOOL)needsHyena;
- (NSString *)queueToKey:(ZBQueueType)queue;
- (ZBQueueType)keyToQueue:(NSString *)key;
- (ZBQueueType)queueStatusForPackageIdentifier:(NSString *)identifier;
- (BOOL)hasErrors;
@end

NS_ASSUME_NONNULL_END
