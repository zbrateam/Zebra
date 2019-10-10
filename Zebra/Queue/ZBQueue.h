//
//  ZBQueue.h
//  Zebra
//
//  Created by Wilson Styres on 1/29/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBPackage;

#import <Foundation/Foundation.h>
#import <Queue/ZBQueueType.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBQueue : NSObject
+ (id)sharedQueue;
+ (int)count;
- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue;
- (void)addPackages:(NSArray <ZBPackage *> *)packages toQueue:(ZBQueueType)queue;
- (void)removePackage:(ZBPackage *)package;
- (void)removePackage:(ZBPackage *)package inQueue:(ZBQueueType)queue;
- (NSArray *)tasksToPerform:(NSArray <NSDictionary <NSString*, NSString *> *> *)debs;
- (NSMutableArray *)queueFromType:(ZBQueueType)queue;
- (ZBQueueType)queueTypeFromKey:(NSString *)key;
- (NSString *)keyFromQueueType:(ZBQueueType)queue;
- (NSString *)queueToKeyDisplayed:(ZBQueueType)queue;
- (NSArray *)actionsToPerform;
- (int)numberOfPackagesInQueueKey:(NSString *)queue;
- (int)numberOfPackagesInQueue:(ZBQueueType)queue;
- (ZBPackage *)packageAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)needsToDownloadPackages;
- (NSArray *)packagesToDownload;
- (BOOL)containsPackage:(ZBPackage *)package inQueue:(ZBQueueType)queue;
- (BOOL)hasIssues;
- (void)clear;
- (BOOL)useIcon;
@end

NS_ASSUME_NONNULL_END
