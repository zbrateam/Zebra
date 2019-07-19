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
    NSMutableDictionary <NSString *, NSMutableArray <ZBPackage *> *> *requiredPackages;
    NSMutableDictionary <NSString *, ZBPackage *> *replacedPackages;
    NSMutableArray <NSString *> *topPackages;
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
        topPackages = [NSMutableArray new];
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
        case ZBQueueTypeClear:
            return @"Clear";
        default:
            break;
    }
    return nil;
}

- (NSString *)queueToKeyDisplayed:(ZBQueueType)queue {
    if (!self.useIcon) {
        return [self queueToKey:queue];
    }
    switch (queue) {
        case ZBQueueTypeInstall:
            return @"↓";
        case ZBQueueTypeRemove:
            return @"╳";
        case ZBQueueTypeUpgrade:
            return @"↑";
        case ZBQueueTypeReinstall:
            return @"↺";
        case ZBQueueTypeSelectable:
            return @"⇵";
        case ZBQueueTypeClear:
            return @"⌧";
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
            for (ZBPackage *p in _managedQueue[key]) {
                if ([p sameAs:package]) {
                    [_managedQueue[key] removeObject:p];
                    return;
                }
            }
        }
    }
}

- (void)addTopPackage:(NSString *)packageIdentifier {
    if (![topPackages containsObject:packageIdentifier]) {
        [topPackages addObject:packageIdentifier];
    }
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue {
    [self addPackage:package toQueue:queue ignoreDependencies:false];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue ignoreDependencies:(BOOL)ignore {
    [self addPackage:package toQueue:queue ignoreDependencies:ignore requiredBy:nil replace:nil toTop:nil];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue replace:(ZBPackage *)oldPackage {
    [self addPackage:package toQueue:queue ignoreDependencies:false requiredBy:nil replace:oldPackage toTop:nil];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue toTop:(nullable ZBPackage *)topPackage {
    [self addPackage:package toQueue:queue ignoreDependencies:false requiredBy:nil replace:nil toTop:nil];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue requiredBy:(nullable ZBPackage *)requiredPackage {
    [self addPackage:package toQueue:queue ignoreDependencies:false requiredBy:requiredPackage replace:nil toTop:nil];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue ignoreDependencies:(BOOL)ignore requiredBy:(nullable ZBPackage *)requiredPackage replace:(nullable ZBPackage *)oldPackage toTop:(nullable ZBPackage *)topPackage {
    NSMutableArray *queueArray = [self queueArray:queue];
    if (![queueArray containsObject:package]) {
        if (queue == ZBQueueTypeReinstall && [package filename] == NULL) {
            //Check to see if the package has a filename to download, if there isn't then we should try to find one
            package = [package installableCandidate];
            if (package == NULL) return;
        }
        packageQueues[package.identifier] = @(queue);
        BOOL added = NO;
        if (requiredPackage) {
            NSUInteger requiredPackageIndex = [queueArray indexOfObject:requiredPackage];
            if (requiredPackageIndex != NSNotFound) {
                [queueArray insertObject:package atIndex:requiredPackageIndex];
                added = YES;
            }
        }
        if (!added) {
            [queueArray addObject:package];
        }
        [self clearPackage:package inOtherQueuesExcept:queue];
        if (!ignore) {
            if (requiredPackage) {
                NSMutableArray *packages = requiredPackages[package.identifier];
                if (packages == nil) {
                    packages = requiredPackages[package.identifier] = [NSMutableArray new];
                }
                if (![packages containsObject:requiredPackage]) {
                    [packages addObject:requiredPackage];
                }
            }
            if (oldPackage) {
                replacedPackages[package.identifier] = oldPackage;
            }
            switch (queue) {
                case ZBQueueTypeInstall:
                    [self enqueueDependenciesForPackage:package];
                    [self checkForConflictionsWithPackage:package state:0];
                    break;
                case ZBQueueTypeUpgrade:
                    [self enqueueDependenciesForPackage:package];
                    [self checkForConflictionsWithPackage:package state:0];
                    break;
                case ZBQueueTypeRemove:
                    [self checkForConflictionsWithPackage:package state:1];
                    if (topPackage) {
                        [self addTopPackage:requiredPackage.identifier];
                    }
                    break;
                default:
                    break;
            }
            if ([self hasErrors]) {
                [ZBPackageActionsManager presentQueue:[[[UIApplication sharedApplication] keyWindow] rootViewController] parent:nil];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
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
    if (queue == 0) {
        for (NSString *key in _managedQueue) {
            if ([_managedQueue[key] containsObject:package]) {
                [_managedQueue[key] removeObject:package];
                [packageQueues removeObjectForKey:package.identifier];
                [replacedPackages removeObjectForKey:package.identifier];
                [requiredPackages removeObjectForKey:package.identifier];
                [topPackages removeObject:package.identifier];
                break;
            }
        }
    }
    else {
        NSString *key = [self queueToKey:queue];
        if (key) {
            [_managedQueue[key] removeObject:package];
            [packageQueues removeObjectForKey:package.identifier];
            [replacedPackages removeObjectForKey:package.identifier];
            [requiredPackages removeObjectForKey:package.identifier];
            [topPackages removeObject:package.identifier];
        }
    }
}

- (NSOrderedSet *)tasks:(NSArray *)debs {
    NSMutableOrderedSet<NSArray *> *commands = [NSMutableOrderedSet new];
    NSArray *baseCommand = @[@"dpkg"];
    
    NSMutableArray *installArray = _managedQueue[[self queueToKey:ZBQueueTypeInstall]];
    NSMutableArray *removeArray = _managedQueue[[self queueToKey:ZBQueueTypeRemove]];
    NSMutableArray *reinstallArray = _managedQueue[[self queueToKey:ZBQueueTypeReinstall]];
    NSMutableArray *upgradeArray = _managedQueue[[self queueToKey:ZBQueueTypeUpgrade]];
    
    NSMutableArray *installCommand = nil;
    NSMutableArray *topInstallCommand = nil;
    
    if ([installArray count]) {
        if (topPackages.count) {
            topInstallCommand = [baseCommand mutableCopy];
            [topInstallCommand insertObject:@"-i" atIndex:1];
        }
        for (ZBPackage *package in installArray) {
            if ([topPackages containsObject:package.identifier]) {
                for (NSString *filename in debs) {
                    if ([filename containsString:[[package filename] lastPathComponent]]) {
                        [topInstallCommand insertObject:filename atIndex:2];
                        break;
                    }
                }
            } else {
                if (installCommand == nil) {
                    installCommand = [baseCommand mutableCopy];
                    [installCommand insertObject:@"-i" atIndex:1];
                }
                for (NSString *filename in debs) {
                    if ([filename containsString:[[package filename] lastPathComponent]]) {
                        [installCommand insertObject:filename atIndex:2];
                        break;
                    }
                }
            }
        }
        
        if (topInstallCommand) {
            [commands addObject:@[@0]];
            [commands addObject:topInstallCommand];
        }
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
    
    if (installCommand && installCommand.count > 2) {
        [commands addObject:@[@0]];
        [commands addObject:installCommand];
    }
    
    if ([reinstallArray count]) {
        [commands addObject:@[@2]];
        
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
    
    return commands;
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

- (nullable NSMutableArray <ZBPackage *> *)packagesRequiredBy:(ZBPackage *)package {
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
    [topPackages removeAllObjects];
    
    [_failedDepQueue removeAllObjects];
    [_failedConQueue removeAllObjects];
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
    if (queue == ZBQueueTypeClear)
        queue = 0;
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
    if (queue == ZBQueueTypeClear)
        queue = 0;
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
