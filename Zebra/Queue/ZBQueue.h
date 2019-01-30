//
//  ZBQueue.h
//  Zebra
//
//  Created by Wilson Styres on 1/29/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBQueueType.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBQueue : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray *> *managedQueue;
+ (id)sharedInstance;
- (void)addPackage:(NSDictionary *)package toQueueWithAction:(ZBQueueType)action;
- (void)addPackages:(NSArray<NSDictionary *> *)packages toQueueWithAction:(ZBQueueType)action;
- (void)removePackage:(NSDictionary *)package fromQueueWithAction:(ZBQueueType)action;
- (NSArray *)tasksForQueue;
- (int)numberOfPackagesForQueue:(NSString *)queue;
- (NSDictionary *)packageInQueueForAction:(ZBQueueType)action atIndex:(int)index;
- (void)clearQueue;
- (NSArray *)actionsToPerform;
- (BOOL)hasObjects;
@end

NS_ASSUME_NONNULL_END
