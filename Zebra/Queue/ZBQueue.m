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
        for (ZBQueueType q = ZBQueueTypeInstall; q <= ZBQueueTypeReinstall; q <<= 1) {
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

- (NSString *)formattedKeyForPackage:(ZBPackage *)package {
    return [NSString stringWithFormat:@"%@-%@", package.identifier, package.version];
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
    for (ZBQueueType q = ZBQueueTypeInstall; q <= ZBQueueTypeReinstall; q <<= 1) {
        if (queue != q) {
            NSString *key = [self queueToKey:q];
            for (ZBPackage *p in _managedQueue[key]) {
                if ([p sameAsStricted:package]) {
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
    [self addPackage:package toQueue:queue ignoreDependencies:NO];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue ignoreDependencies:(BOOL)ignore {
    [self addPackage:package toQueue:queue ignoreDependencies:ignore requiredBy:nil replace:nil toTop:nil];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue replace:(ZBPackage *)oldPackage {
    [self addPackage:package toQueue:queue ignoreDependencies:NO requiredBy:nil replace:oldPackage toTop:nil];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue toTop:(nullable ZBPackage *)topPackage {
    [self addPackage:package toQueue:queue ignoreDependencies:NO requiredBy:nil replace:nil toTop:nil];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue requiredBy:(nullable ZBPackage *)requiredPackage {
    [self addPackage:package toQueue:queue ignoreDependencies:NO requiredBy:requiredPackage replace:nil toTop:nil];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue ignoreDependencies:(BOOL)ignore requiredBy:(nullable ZBPackage *)requiredPackage replace:(nullable ZBPackage *)oldPackage toTop:(nullable ZBPackage *)topPackage {
    NSMutableArray *queueArray = [self queueArray:queue];
    if (queue == ZBQueueTypeUpgrade) {
        ZBPackage *topPackage = [[ZBDatabaseManager sharedInstance] topVersionForPackage:package];
        if (![topPackage sameAsStricted:package]) {
            NSString *formattedKey = [self formattedKeyForPackage:topPackage];
            replacedPackages[formattedKey] = package;
            package = topPackage;
        }
    }
    if (![self queueArray:queueArray containsPackageWithVersion:package]) {
        if (queue == ZBQueueTypeReinstall && [package filename] == NULL) {
            // Check to see if the package has a filename to download, if there isn't then we should try to find one
            package = [package installableCandidate];
            if (package == NULL) return;
        }
        NSString *formattedKey = [self formattedKeyForPackage:package];
        packageQueues[formattedKey] = @(queue);
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
                NSMutableArray *packages = requiredPackages[formattedKey];
                if (packages == nil) {
                    packages = requiredPackages[formattedKey] = [NSMutableArray new];
                }
                if (![packages containsObject:requiredPackage]) {
                    [packages addObject:requiredPackage];
                }
            }
            if (oldPackage) {
                replacedPackages[formattedKey] = oldPackage;
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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBUpdateQueueBar" object:nil];
    }
}

- (void)addPackages:(NSArray<ZBPackage *> *)packages toQueue:(ZBQueueType)queue {
    for (ZBPackage *package in packages) {
        [self addPackage:package toQueue:queue ignoreDependencies:YES];
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
                NSString *formattedKey = [self formattedKeyForPackage:package];
                [packageQueues removeObjectForKey:formattedKey];
                [replacedPackages removeObjectForKey:formattedKey];
                [requiredPackages removeObjectForKey:formattedKey];
                [topPackages removeObject:package.identifier];
                break;
            }
        }
    } else {
        NSString *key = [self queueToKey:queue];
        if (key) {
            [_managedQueue[key] removeObject:package];
            NSString *formattedKey = [self formattedKeyForPackage:package];
            [packageQueues removeObjectForKey:formattedKey];
            [replacedPackages removeObjectForKey:formattedKey];
            [requiredPackages removeObjectForKey:formattedKey];
            [topPackages removeObject:package.identifier];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBUpdateQueueBar" object:nil];
}

- (NSArray *)tasks:(NSArray *)debs {
    NSMutableArray<NSArray *> *commands = [NSMutableArray new];
    NSArray *baseCommand = @[@"apt", @"-yqf", @"--allow-downgrades", @"-oApt::Get::HideAutoRemove=true", @"-oquiet::NoProgress=true", @"-oquiet::NoStatistic=true"];
    
    NSMutableArray *installArray = _managedQueue[[self queueToKey:ZBQueueTypeInstall]];
    NSMutableArray *removeArray = _managedQueue[[self queueToKey:ZBQueueTypeRemove]];
    NSMutableArray *reinstallArray = _managedQueue[[self queueToKey:ZBQueueTypeReinstall]];
    NSMutableArray *upgradeArray = _managedQueue[[self queueToKey:ZBQueueTypeUpgrade]];
    
    NSMutableArray *installCommand = nil;
    NSMutableArray *topInstallCommand = nil;
    
    if ([installArray count]) {
        if (topPackages.count) {
            topInstallCommand = [baseCommand mutableCopy];
            [topInstallCommand addObject:@"install"];
        }
        for (ZBPackage *package in installArray) {
            if ([topPackages containsObject:package.identifier]) {
                for (NSString *filename in debs) {
                    if ([filename containsString:[[package filename] lastPathComponent]]) {
                        [topInstallCommand addObject:filename];
                        break;
                    }
                }
            } else {
                if (installCommand == nil) {
                    installCommand = [baseCommand mutableCopy];
                    [installCommand addObject:@"install"];
                    [installCommand addObject:@"--reinstall"];
                }
                for (NSString *filename in debs) {
                    NSString *packageFilename = [package filename];
                    if (packageFilename == nil) {
                        continue;
                    }
                    if ([filename containsString:[packageFilename lastPathComponent]]) {
                        [installCommand addObject:filename];
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
        
        [removeCommand addObject:@"remove"];
        for (ZBPackage *package in removeArray) {
            [removeCommand addObject:package.identifier];
        }
        
        [commands addObject:removeCommand];
    }
    
    if (installCommand && installCommand.count > 2) {
        [commands addObject:@[@0]];
        [commands addObject:installCommand];
    }
    
    if ([reinstallArray count]) {
        [commands addObject:@[@2]];
        
        // Install new version
        NSMutableArray *installCommand = [baseCommand mutableCopy];
        
        [installCommand addObject:@"install"];
        [installCommand addObject:@"--reinstall"];
        for (ZBPackage *package in reinstallArray) {
            for (NSString *filename in debs) {
                if ([filename containsString:[[package filename] lastPathComponent]]) {
                    [installCommand addObject:filename];
                    break;
                }
            }
        }
        
        [commands addObject:installCommand];
    }
    
    if ([upgradeArray count]) {
        [commands addObject:@[@3]];
        NSMutableArray *upgradeCommand = [baseCommand mutableCopy];
        
        [upgradeCommand addObject:@"install"];
        for (ZBPackage *package in upgradeArray) {
            for (NSString *filename in debs) {
                if ([filename containsString:[[package filename] lastPathComponent]]) {
                    [upgradeCommand addObject:filename];
                    break;
                }
            }
        }
        
        [commands addObject:upgradeCommand];
    }
    
    return commands;
}

- (int)numberOfPackagesForQueue:(NSString *)queue {
    if ([queue isEqualToString:@"Unresolved Dependencies"])
        return (int)[_failedDepQueue count];
    if ([queue isEqualToString:@"Conflictions"])
        return (int)[_failedConQueue count];
    return (int)[_managedQueue[queue] count];
}

- (ZBPackage *)packageInQueue:(ZBQueueType)queue atIndex:(NSInteger)index {
    NSMutableArray *queueArray = [self queueArray:queue];
    return queueArray ? queueArray[index] : nil;
}

- (nullable ZBPackage *)packageReplacedBy:(ZBPackage *)package {
    return replacedPackages[[self formattedKeyForPackage:package]];
}

- (nullable NSMutableArray <ZBPackage *> *)packagesRequiredBy:(ZBPackage *)package {
    return requiredPackages[[self formattedKeyForPackage:package]];
}

- (ZBQueueType)queueStatusForPackage:(ZBPackage *)package {
    return [packageQueues[[self formattedKeyForPackage:package]] intValue];
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
    
    return actions;
}

- (BOOL)hasObjects {
    for (NSString *key in _managedQueue) {
        if ([_managedQueue[key] count]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)containsPackageName:(NSString *)packageName queue:(ZBQueueType)queue {
    if (queue == ZBQueueTypeClear)
        queue = 0;
    if (queue == 0) {
        for (NSString *key in _managedQueue) {
            for (ZBPackage *package in _managedQueue[key]) {
                if ([packageName isEqualToString:package.identifier]) {
                    return YES;
                }
            }
        }
    } else {
        NSMutableArray *queueArray = [self queueArray:queue];
        if (!queueArray) return NO;
        for (ZBPackage *p in queueArray) {
            if ([packageName isEqualToString:p.identifier]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)containsPackage:(ZBPackage *)package queue:(ZBQueueType)queue {
    if (queue == ZBQueueTypeClear)
        queue = 0;
    if (queue == 0) {
        for (NSString *key in _managedQueue) {
            if ([_managedQueue[key] containsObject:package]) {
                return YES;
            }
        }
    } else {
        NSMutableArray *queueArray = [self queueArray:queue];
        if (!queueArray) return NO;
        for (ZBPackage *p in queueArray) {
            if ([p sameAs:package]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)queueArray:(NSArray *)queueArray containsPackageWithVersion:(ZBPackage *)package {
    for (ZBPackage *p in queueArray) {
        if ([p sameAsStricted:package]) {
            return YES;
        }
    }
    return NO;
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
            return YES;
        }
    }
    return NO;
}

- (BOOL)hasErrors {
    return [_failedDepQueue count] || [_failedConQueue count];
}

@end
