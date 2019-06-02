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

@interface ZBQueue () {
    NSMutableDictionary <NSString *, NSNumber *> *packageQueues;
    NSMutableDictionary <NSString *, NSMutableArray <NSString *> *> *requiredPackages;
    NSMutableDictionary <NSString *, ZBPackage *> *replacedPackages;
}
@end

@implementation ZBQueue
+ (id)sharedInstance {
    static ZBQueue *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBQueue new];
    });
    return instance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        _managedQueue = [NSMutableDictionary new];
        for (ZBQueueType q = ZBQueueTypeInstall; q <= ZBQueueTypeUpgrade; q <<= 1) {
            [_managedQueue setObject:[NSMutableArray array] forKey:[self queueToKey:q]];
        }
        
        _failedDepQueue = [NSMutableArray new];
        _failedConQueue = [NSMutableArray new];
        
        packageQueues = [NSMutableDictionary new];
        requiredPackages = [NSMutableDictionary new];
        replacedPackages = [NSMutableDictionary new];
    }
    
    return self;
}

- (ZBQueueType)keyToQueue:(NSString *)key {
    NSArray *keys = @[ @"Install", @"Remove", @"Reinstall", @"Upgrade" ];
    switch ([keys indexOfObject:key]) {
        case 0:
            return ZBQueueTypeInstall;
        case 1:
            return ZBQueueTypeRemove;
        case 2:
            return ZBQueueTypeReinstall;
        case 3:
            return ZBQueueTypeUpgrade;
        default:
            return 0;
    }
}

- (NSString *)queueToKey:(ZBQueueType)queue {
    switch (queue) {
        case ZBQueueTypeInstall:
            return @"Install";
        case ZBQueueTypeRemove:
            return @"Remove";
        case ZBQueueTypeUpgrade:
            return @"Upgrade";
        case ZBQueueTypeReinstall:
            return @"Reinstall";
        case ZBQueueTypeSelectable:
            return @"Select Ver.";
        default:
            break;
    }
    return nil;
}

- (NSMutableArray *)queueArray:(ZBQueueType)queue {
    NSString *key = [self queueToKey:queue];
    return key ? _managedQueue[key] : nil;
}

- (void)clearPackage:(ZBPackage *)package inOtherQueuesExcept:(ZBQueueType)queue {
    for (ZBQueueType q = ZBQueueTypeInstall; q <= ZBQueueTypeUpgrade; q <<= 1) {
        if (queue != q) {
            NSString *key = [self queueToKey:q];
            ZBPackage *samePackage = nil;
            for (ZBPackage *p in _managedQueue[key]) {
                if ([p sameAs:package]) {
                    samePackage = p;
                    break;
                }
            }
            if (samePackage) {
                [_managedQueue[key] removeObject:samePackage];
            }
        }
    }
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue {
    [self addPackage:package toQueue:queue ignoreDependencies:false];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue replace:(ZBPackage *)oldPackage {
    [self addPackage:package toQueue:queue ignoreDependencies:false requiredBy:nil replace:oldPackage];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue requiredBy:(nullable ZBPackage *)requiredPackage {
    [self addPackage:package toQueue:queue ignoreDependencies:false requiredBy:requiredPackage replace:nil];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue ignoreDependencies:(BOOL)ignore {
    [self addPackage:package toQueue:queue ignoreDependencies:ignore requiredBy:nil replace:nil];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue ignoreDependencies:(BOOL)ignore requiredBy:(nullable ZBPackage *)requiredPackage replace:(nullable ZBPackage *)oldPackage {
    NSMutableArray *queueArray = [self queueArray:queue];
    if (![queueArray containsObject:package]) {
        if (queue == ZBQueueTypeReinstall && [package filename] == NULL) {
            //Check to see if the package has a filename to download, if there isn't then we should try to find one
            package = [package installableCandidate];
            if (package == NULL) return;
        }
        packageQueues[package.identifier] = @(queue);
        [queueArray addObject:package];
        [self clearPackage:package inOtherQueuesExcept:queue];
        if (!ignore) {
            switch (queue) {
                case ZBQueueTypeInstall:
                    if (requiredPackage) {
                        NSMutableArray *packages = requiredPackages[package.identifier];
                        if (packages == nil) {
                            packages = requiredPackages[package.identifier] = [NSMutableArray new];
                        }
                        if (![packages containsObject:requiredPackage.name]) {
                            [packages addObject:requiredPackage.name];
                        }
                    }
                    if (oldPackage) {
                        replacedPackages[package.identifier] = oldPackage;
                    }
                    [self enqueueDependenciesForPackage:package];
                case ZBQueueTypeUpgrade:
                    [self checkForConflictionsWithPackage:package state:0];
                    break;
                case ZBQueueTypeRemove:
                    [self checkForConflictionsWithPackage:package state:1];
                    break;
                default:
                    break;
            }
            if ([self hasErrors]) {
                [ZBPackageActionsManager presentQueue:[[[UIApplication sharedApplication] keyWindow] rootViewController] parent:nil];
            }
        }
    }
}

- (void)addPackages:(NSArray<ZBPackage *> *)packages toQueue:(ZBQueueType)queue {
    for (ZBPackage *package in packages) {
        [self addPackage:package toQueue:queue ignoreDependencies:true];
    }
    
    NSString *key = [self queueToKey:queue];
    
    if (key) {
        for (ZBPackage *package in _managedQueue[key]) {
            [self enqueueDependenciesForPackage:package];
            [self checkForConflictionsWithPackage:package state:queue == ZBQueueTypeRemove ? 1 : 0];
        }
    }
}

- (void)markPackageAsFailed:(ZBPackage *)package forDependency:(NSString *)failedDependency {
    NSArray *unresolvedDep = @[failedDependency, package];
    [_failedDepQueue addObject:unresolvedDep];
}

- (void)markPackageAsFailed:(ZBPackage *)package forConflicts:(ZBPackage *)conflict conflictionType:(int)type {
    NSArray *conflicts = @[[NSNumber numberWithInt:type], conflict, package];
    [_failedConQueue addObject:conflicts];
}

- (void)removePackage:(ZBPackage *)package fromQueue:(ZBQueueType)queue {
    NSString *key = [self queueToKey:queue];
    if (key) {
        [_managedQueue[key] removeObject:package];
        [packageQueues removeObjectForKey:package.identifier];
        [replacedPackages removeObjectForKey:package.identifier];
        [requiredPackages removeObjectForKey:package.identifier];
    }
}

- (NSArray *)tasks:(NSArray *)debs {
    NSMutableArray<NSArray *> *commands = [NSMutableArray new];
    NSArray *baseCommand = @[@"dpkg"];
    
    NSMutableArray *installArray = _managedQueue[[self queueToKey:ZBQueueTypeInstall]];
    NSMutableArray *removeArray = _managedQueue[[self queueToKey:ZBQueueTypeRemove]];
    NSMutableArray *reinstallArray = _managedQueue[[self queueToKey:ZBQueueTypeReinstall]];
    NSMutableArray *upgradeArray = _managedQueue[[self queueToKey:ZBQueueTypeUpgrade]];
    
    if ([installArray count]) {
        [commands addObject:@[@0]];
        NSMutableArray *installCommand = [baseCommand mutableCopy];
        
        [installCommand insertObject:@"-i" atIndex:1];
        for (ZBPackage *package in installArray) {
            for (NSString *filename in debs) {
                if ([filename containsString:[[package filename] lastPathComponent]]) {
                    [installCommand insertObject:filename atIndex:2];
                    break;
                }
            }
        }
        
        [commands addObject:installCommand];
    }
    
    if ([removeArray count]) {
        [commands addObject:@[@1]];
        NSMutableArray *removeCommand = [baseCommand mutableCopy];
        
        [removeCommand insertObject:@"-r" atIndex:1];
        for (ZBPackage *package in removeArray) {
            [removeCommand insertObject:[package identifier] atIndex:2];
        }
        
        [commands addObject:removeCommand];
    }
    
    if ([reinstallArray count]) {
        [commands addObject:@[@2]];
        
        //Remove package first
        NSMutableArray *removeCommand = [baseCommand mutableCopy];
        
        [removeCommand insertObject:@"-r" atIndex:1];
        [removeCommand insertObject:@"--force-depends" atIndex:2];
        for (ZBPackage *package in reinstallArray) {
            [removeCommand insertObject:[package identifier] atIndex:3];
        }
        [commands addObject:removeCommand];
        
        //Install new version
        NSMutableArray *installCommand = [baseCommand mutableCopy];
        
        [installCommand insertObject:@"-i" atIndex:1];
        for (ZBPackage *package in reinstallArray) {
            for (NSString *filename in debs) {
                if ([filename containsString:[[package filename] lastPathComponent]]) {
                    [installCommand insertObject:filename atIndex:2];
                    break;
                }
            }
        }
        
        [commands addObject:installCommand];
    }
    
    if ([upgradeArray count]) {
        [commands addObject:@[@3]];
        NSMutableArray *upgradeCommand = [baseCommand mutableCopy];
        
        [upgradeCommand insertObject:@"-i" atIndex:1];
        for (ZBPackage *package in upgradeArray) {
            for (NSString *filename in debs) {
                if ([filename containsString:[[package filename] lastPathComponent]]) {
                    [upgradeCommand insertObject:filename atIndex:2];
                    break;
                }
            }
        }
        
        [commands addObject:upgradeCommand];
    }
    
    return (NSArray *)commands;
}

- (int)numberOfPackagesForQueue:(NSString *)queue {
    if ([queue isEqualToString:@"Unresolved Dependencies"]) {
        return (int)[_failedDepQueue count];
    }
    else if ([queue isEqualToString:@"Conflictions"]) {
        return (int)[_failedConQueue count];
    }
    else {
        return (int)[_managedQueue[queue] count];
    }
}

- (ZBPackage *)packageInQueue:(ZBQueueType)queue atIndex:(NSInteger)index {
    NSMutableArray *queueArray = [self queueArray:queue];
    return queueArray ? queueArray[index] : nil;
}

- (nullable ZBPackage *)packageReplacedBy:(ZBPackage *)package {
    return replacedPackages[package.identifier];
}

- (nullable NSMutableArray <NSString *> *)packagesRequiredBy:(ZBPackage *)package {
    return requiredPackages[package.identifier];
}

- (ZBQueueType)queueStatusForPackageIdentifier:(NSString *)identifier {
    return [packageQueues[identifier] intValue];
}

- (void)clearQueue {
    for (NSString *key in _managedQueue) {
        [_managedQueue[key] removeAllObjects];
    }
    [packageQueues removeAllObjects];
    [requiredPackages removeAllObjects];
    [replacedPackages removeAllObjects];
    
    _failedDepQueue = [NSMutableArray new];
    _failedConQueue = [NSMutableArray new];
}

- (NSArray *)actionsToPerform {
    NSMutableArray *actions = [NSMutableArray new];
    
    if ([_failedDepQueue count]) {
        [actions addObject:@"Unresolved Dependencies"];
    }
    
    if ([_failedConQueue count]) {
        [actions addObject:@"Conflictions"];
    }
    
    for (NSString *key in _managedQueue) {
        if ([_managedQueue[key] count]) {
            [actions addObject:key];
        }
    }
    
    return (NSArray *)actions;
}

- (BOOL)hasObjects {
    for (NSString *key in _managedQueue) {
        if ([_managedQueue[key] count]) {
            return true;
        }
    }
    return false;
}

- (BOOL)containsPackageName:(NSString *)packageName queue:(ZBQueueType)queue {
    if (queue == 0) {
        for (NSString *key in _managedQueue) {
            for (ZBPackage *package in _managedQueue[key]) {
                if ([packageName isEqualToString:package.identifier]) {
                    return true;
                }
            }
        }
    }
    else {
        NSMutableArray *queueArray = [self queueArray:queue];
        if (!queueArray) return false;
        for (ZBPackage *p in queueArray) {
            if ([packageName isEqualToString:p.identifier]) {
                return true;
            }
        }
    }
    return false;
}

- (BOOL)containsPackage:(ZBPackage *)package queue:(ZBQueueType)queue {
    if (queue == 0) {
        for (NSString *key in _managedQueue) {
            if ([_managedQueue[key] containsObject:package]) {
                return true;
            }
        }
    }
    else {
        NSMutableArray *queueArray = [self queueArray:queue];
        if (!queueArray) return false;
        for (ZBPackage *p in queueArray) {
            if ([p sameAs:package]) {
                return true;
            }
        }
    }
    return false;
}

- (BOOL)containsPackage:(ZBPackage *)package {
    return [self containsPackage:package queue:0];
}

- (void)enqueueDependenciesForPackage:(ZBPackage *)package {
    ZBDependencyResolver *resolver = [[ZBDependencyResolver alloc] init];
    [resolver addDependenciesForPackage:package];
}

- (void)checkForConflictionsWithPackage:(ZBPackage *)package state:(int)state {
    ZBDependencyResolver *resolver = [[ZBDependencyResolver alloc] init];
    [resolver conflictionsWithPackage:package state:state];
}

- (NSArray *)packagesToDownload {
    NSMutableArray *packages = [NSMutableArray new];
    
    for (NSString *key in _managedQueue) {
        if (![key isEqualToString:@"Remove"]) {
            [packages addObjectsFromArray:_managedQueue[key]];
        }
    }
    
    return (NSArray *)packages;
}

- (BOOL)needsHyena {
    for (NSString *key in _managedQueue) {
        if (![key isEqualToString:@"Remove"] && [_managedQueue[key] count]) {
            return true;
        }
    }
    return false;
}

- (BOOL)hasErrors {
    return [_failedDepQueue count] || [_failedConQueue count];
}

@end
