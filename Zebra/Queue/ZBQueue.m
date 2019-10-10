//
//  ZBQueue.m
//  Zebra
//
//  Created by Wilson Styres on 1/29/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueue.h"
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActionsManager.h>
#import <ZBAppDelegate.h>
#import <Database/ZBDependencyResolver.h>
#import <Database/ZBDatabaseManager.h>

@interface ZBQueue ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *managedQueue;
@end

@implementation ZBQueue

@synthesize managedQueue;

+ (id)sharedQueue {
    static ZBQueue *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBQueue new];
    });
    return instance;
}

+ (int)count {
    int totalPackages = 0;
    for (NSArray *queue in [[ZBQueue sharedQueue] queues]) {
        totalPackages += [queue count];
    }
    return totalPackages;
}

- (id)init {
    self = [super init];
    
    if (self) {
        managedQueue = [NSMutableDictionary new];
        for (ZBQueueType q = ZBQueueTypeInstall; q <= ZBQueueTypeDowngrade; q <<= 1) {
            [managedQueue setObject:[NSMutableArray new] forKey:[self keyFromQueueType:q]];
        }
    }
    
    return self;
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue {
    [[self queueFromType:queue] addObject:package];
}

- (void)addPackages:(NSArray <ZBPackage *> *)packages toQueue:(ZBQueueType)queue {
    for (ZBPackage *package in packages) {
        [self addPackage:package toQueue:queue];
    }
}

- (void)removePackage:(ZBPackage *)package {
    for (NSMutableArray *queue in [self queues]) {
        [queue removeObject:package];
    }
}

- (void)removePackage:(ZBPackage *)package inQueue:(ZBQueueType)queue {
    [[self queueFromType:queue] removeObject:package];
}

- (NSArray *)tasksToPerform:(NSArray <NSDictionary <NSString*, NSString *> *> *)debs {
    NSMutableArray<NSArray *> *commands = [NSMutableArray new];
    NSArray *baseCommand = @[@"apt", @"-yqf", @"--allow-downgrades", @"-oApt::Get::HideAutoRemove=true", @"-oquiet::NoProgress=true", @"-oquiet::NoStatistic=true"];

    if ([self queueHasPackages:ZBQueueTypeInstall]) {
        NSMutableArray *installCommand = [baseCommand mutableCopy];
        [installCommand addObject:@"install"];
        [installCommand addObject:@"--reinstall"];
        
        NSArray *paths = [self pathsForDownloadedDebsInQueue:ZBQueueTypeInstall filenames:debs];
        [installCommand addObjectsFromArray:paths];
        
        [commands addObject:@[@0]];
        [commands addObject:installCommand];
    }
    
    if ([self queueHasPackages:ZBQueueTypeReinstall]) {
        NSMutableArray *reinstallCommand = [baseCommand mutableCopy];
        [reinstallCommand addObject:@"install"];
        [reinstallCommand addObject:@"--reinstall"];
        
        NSArray *paths = [self pathsForDownloadedDebsInQueue:ZBQueueTypeReinstall filenames:debs];
        [reinstallCommand addObjectsFromArray:paths];
        
        [commands addObject:@[@1]];
        [commands addObject:reinstallCommand];
    }
    
    if ([self queueHasPackages:ZBQueueTypeRemove]) {
        NSMutableArray *removeCommand = [baseCommand mutableCopy];
        [removeCommand addObject:@"remove"];
        
        for (ZBPackage *package in [self removeQueue]) {
            [removeCommand addObject:package.identifier];
        }
        
        [commands addObject:@[@2]];
        [commands addObject:removeCommand];
    }
    
    if ([self queueHasPackages:ZBQueueTypeUpgrade]) {
        NSMutableArray *upgradeCommand = [baseCommand mutableCopy];
        [upgradeCommand addObject:@"install"];
        
        NSArray *paths = [self pathsForDownloadedDebsInQueue:ZBQueueTypeUpgrade filenames:debs];
        [upgradeCommand addObjectsFromArray:paths];

        [commands addObject:@[@3]];
        [commands addObject:upgradeCommand];
    }
    
    if ([self queueHasPackages:ZBQueueTypeDowngrade]) {
        NSMutableArray *downgradeCommand = [baseCommand mutableCopy];
        [downgradeCommand addObject:@"install"];
        
        NSArray *paths = [self pathsForDownloadedDebsInQueue:ZBQueueTypeDowngrade filenames:debs];
        [downgradeCommand addObjectsFromArray:paths];

        [commands addObject:@[@4]];
        [commands addObject:downgradeCommand];
    }
    
    return commands;
}

- (NSArray <NSString *> *)pathsForDownloadedDebsInQueue:(ZBQueueType)queue filenames:(NSArray <NSDictionary <NSString*, NSString *> *> *)filenames {
    NSMutableArray *paths = [NSMutableArray new];
    for (ZBPackage *package in [self queueFromType:queue]) {
        for (NSDictionary *filename in filenames) {
            NSString *finalPath = [filename objectForKey:@"final"];
            NSString *originalFilename = [filename objectForKey:@"original"];
            NSString *packageFilename = [[package filename] lastPathComponent];

            if (packageFilename == nil || originalFilename == nil || finalPath == nil) {
                continue;
            }
            
            if ([finalPath containsString:packageFilename]) {
                [paths addObject:finalPath];
                break;
            }
            else if ([originalFilename containsString:packageFilename]) {
                [paths addObject:finalPath];
                break;
            }
            else if ([packageFilename containsString:originalFilename]) {
                [paths addObject:finalPath];
                break;
            }
        }
    }
    
    return paths;
}

- (NSMutableArray *)queueFromType:(ZBQueueType)queue {
    return managedQueue[[self keyFromQueueType:queue]];
}

- (ZBQueueType)queueTypeFromKey:(NSString *)key {
    NSArray *keys = @[@"install", @"reinstall", @"remove", @"upgrade", @"downgrade"];
    switch ([keys indexOfObject:[key lowercaseString]]) {
        case 0:
            return ZBQueueTypeInstall;
        case 1:
            return ZBQueueTypeReinstall;
        case 2:
            return ZBQueueTypeRemove;
        case 3:
            return ZBQueueTypeUpgrade;
        case 4:
            return ZBQueueTypeDowngrade;
        default:
            return -1;
    }
}

- (NSString *)keyFromQueueType:(ZBQueueType)queue {
    switch (queue) {
        case ZBQueueTypeInstall:
            return @"install";
        case ZBQueueTypeReinstall:
            return @"reinstall";
        case ZBQueueTypeRemove:
            return @"remove";
        case ZBQueueTypeUpgrade:
            return @"upgrade";
        case ZBQueueTypeDowngrade:
            return @"downgrade";
        default:
            break;
    }
    return NULL;
}

- (BOOL)queueHasPackages:(ZBQueueType)queue {
    return [managedQueue[[self keyFromQueueType:queue]] count] > 0;
}

- (NSString *)queueToKeyDisplayed:(ZBQueueType)queue {
    if (![self useIcon]) {
        return [self keyFromQueueType:queue];
    }
    switch (queue) {
        case ZBQueueTypeInstall:
            return @"↓";
        case ZBQueueTypeReinstall:
            return @"↺";
        case ZBQueueTypeRemove:
            return @"╳";
        case ZBQueueTypeUpgrade:
            return @"↑";
        case ZBQueueTypeDowngrade:
            return @"⇵";
        default:
            break;
    }
    return nil;
}

- (NSArray *)actionsToPerform {
    NSMutableArray *actions = [NSMutableArray new];
    for (NSString *key in managedQueue) {
        if ([managedQueue[key] count]) {
            [actions addObject:key];
        }
    }
    
    return actions;
}

- (int)numberOfPackagesInQueueKey:(NSString *)queue {
    return [self numberOfPackagesInQueue:[self queueTypeFromKey:queue]];
}

- (int)numberOfPackagesInQueue:(ZBQueueType)queue {
    switch (queue) {
        case ZBQueueTypeInstall:
            return (int)[[self installQueue] count];
        case ZBQueueTypeReinstall:
            return (int)[[self reinstallQueue] count];
        case ZBQueueTypeRemove:
            return (int)[[self removeQueue] count];
        case ZBQueueTypeUpgrade:
            return (int)[[self upgradeQueue] count];
        case ZBQueueTypeDowngrade:
            return (int)[[self downgradeQueue] count];
        default:
            break;
    }
    
    return -1;
}

- (ZBPackage *)packageAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *actions = [self actionsToPerform];
    NSString *key = [actions objectAtIndex:indexPath.section];
    
    return [[self queueFromType:[self queueTypeFromKey:key]] objectAtIndex:indexPath.row];
}

- (BOOL)needsToDownloadPackages {
    for (NSString *key in managedQueue) {
        if (![key isEqualToString:@"Remove"] && [managedQueue[key] count]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSArray *)packagesToDownload {
    NSMutableArray *packages = [NSMutableArray new];
    for (NSString *key in managedQueue) {
        if (![key isEqualToString:@"Remove"]) {
            [packages addObjectsFromArray:managedQueue[key]];
        }
    }
    
    return (NSArray *)packages;
}

- (BOOL)containsPackage:(ZBPackage *)package inQueue:(ZBQueueType)queue {
    if (queue == ZBQueueTypeClear)
        queue = 0;
    
    if (queue == 0) {
        for (NSString *key in managedQueue) {
            if ([managedQueue[key] containsObject:package]) {
                return YES;
            }
        }
    } else {
        NSMutableArray *queueArray = [self queueFromType:queue];
        if (!queueArray) return NO;
        for (ZBPackage *p in queueArray) {
            if ([p sameAs:package]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)hasIssues {
    return false;
}

- (BOOL)useIcon {
    return false;
}

- (NSArray <NSMutableArray *> *)queues {
    return @[[self installQueue], [self reinstallQueue], [self removeQueue], [self upgradeQueue], [self downgradeQueue]];
}

- (NSMutableArray *)installQueue {
    return managedQueue[[self keyFromQueueType:ZBQueueTypeInstall]];
}

- (NSMutableArray *)reinstallQueue {
    return managedQueue[[self keyFromQueueType:ZBQueueTypeReinstall]];
}

- (NSMutableArray *)removeQueue {
    return managedQueue[[self keyFromQueueType:ZBQueueTypeRemove]];
}

- (NSMutableArray *)upgradeQueue {
    return managedQueue[[self keyFromQueueType:ZBQueueTypeUpgrade]];
}

- (NSMutableArray *)downgradeQueue {
    return managedQueue[[self keyFromQueueType:ZBQueueTypeDowngrade]];
}

@end
