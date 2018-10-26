//
//  AUPMQueue.h
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AUPMQueueAction.h"

NS_ASSUME_NONNULL_BEGIN

@class AUPMPackage;

@interface AUPMQueue : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray *> *managedQueue;
+ (id)sharedInstance;
- (void)addPackage:(AUPMPackage *)package toQueueWithAction:(AUPMQueueAction)action;
- (void)addPackages:(NSArray<AUPMPackage *> *)packages toQueueWithAction:(AUPMQueueAction)action;
- (void)removePackage:(AUPMPackage *)package fromQueueWithAction:(AUPMQueueAction)action;
- (NSArray *)tasksForQueue;
- (int)numberOfPackagesForQueue:(NSString *)queue;
- (AUPMPackage *)packageInQueueForAction:(AUPMQueueAction)action atIndex:(int)index;
- (void)clearQueue;
- (NSArray *)actionsToPerform;
- (BOOL)hasObjects;
@end

NS_ASSUME_NONNULL_END
