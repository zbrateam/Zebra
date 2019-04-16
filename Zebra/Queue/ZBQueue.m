//
//  ZBQueue.m
//  Zebra
//
//  Created by Wilson Styres on 1/29/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueue.h"
#import <Packages/Helpers/ZBPackage.h>
#import <ZBAppDelegate.h>
#import <Database/ZBDependencyResolver.h>

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
        [_managedQueue setObject:@[] forKey:@"Install"];
        [_managedQueue setObject:@[] forKey:@"Remove"];
        [_managedQueue setObject:@[] forKey:@"Reinstall"];
        [_managedQueue setObject:@[] forKey:@"Upgrade"];
        
        _failedDepQueue = [NSMutableArray new];
        _failedConQueue = [NSMutableArray new];
    }
    
    return self;
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue {
    [self addPackage:package toQueue:queue ignoreDependencies:false];
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue ignoreDependencies:(BOOL)ignore {
    switch (queue) {
        case ZBQueueTypeInstall: {
            NSMutableArray *installArray = [_managedQueue[@"Install"] mutableCopy];
            if (![installArray containsObject:package]) {                
                [installArray addObject:package];
                [_managedQueue setObject:installArray forKey:@"Install"];
                if (!ignore) {
                    [self enqueueDependenciesForPackage:package];
                    [self checkForConflictionsWithPackage:package state:0];
                }
            }
            break;
        }
        case ZBQueueTypeRemove: {
            NSMutableArray *removeArray = [_managedQueue[@"Remove"] mutableCopy];
            if (![removeArray containsObject:package]) {
                [removeArray addObject:package];
                [_managedQueue setObject:removeArray forKey:@"Remove"];
                if (!ignore) {
                    [self checkForConflictionsWithPackage:package state:1];
                }
            }
            break;
        }
        case ZBQueueTypeReinstall: {
            NSMutableArray *reinstallArray = [_managedQueue[@"Reinstall"] mutableCopy];
            if (![reinstallArray containsObject:package]) {
                [reinstallArray addObject:package];
                [_managedQueue setObject:reinstallArray forKey:@"Reinstall"];
            }
            break;
        }
        case ZBQueueTypeUpgrade: {
            NSMutableArray *upgradeArray = [_managedQueue[@"Upgrade"] mutableCopy];
            if (![upgradeArray containsObject:package]) {
                [upgradeArray addObject:package];
                [_managedQueue setObject:upgradeArray forKey:@"Upgrade"];
                if (!ignore) {
                    [self enqueueDependenciesForPackage:package];
                    [self checkForConflictionsWithPackage:package state:0];
                }
            }
            break;
        }
    }
}

- (void)addPackages:(NSArray<ZBPackage *> *)packages toQueue:(ZBQueueType)queue {
    for (ZBPackage *package in packages) {
        [self addPackage:package toQueue:queue ignoreDependencies:true];
    }
    
    NSString *q;
    switch (queue) {
        case ZBQueueTypeInstall: {
            q = @"Install";
        }
        case ZBQueueTypeRemove: {
            q = @"Remove";
        }
        case ZBQueueTypeReinstall: {
            q = @"Reinstall";
        }
        case ZBQueueTypeUpgrade: {
            q = @"Upgrade";
        }
    }
    
    for (ZBPackage *package in _managedQueue[q]) {
        [self enqueueDependenciesForPackage:package];
        [self checkForConflictionsWithPackage:package state:queue == ZBQueueTypeRemove ? 1 : 0];
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
    switch (queue) {
        case ZBQueueTypeInstall: {
            NSMutableArray *installArray = [_managedQueue[@"Install"] mutableCopy];
            [installArray removeObject:package];
            [_managedQueue setObject:installArray forKey:@"Install"];
            break;
        }
        case ZBQueueTypeRemove: {
            NSMutableArray *removeArray = [_managedQueue[@"Remove"] mutableCopy];
            [removeArray removeObject:package];
            [_managedQueue setObject:removeArray forKey:@"Remove"];
            break;
        }
        case ZBQueueTypeReinstall: {
            NSMutableArray *reinstallArray = [_managedQueue[@"Reinstall"] mutableCopy];
            [reinstallArray removeObject:package];
            [_managedQueue setObject:reinstallArray forKey:@"Reinstall"];
            break;
        }
        case ZBQueueTypeUpgrade: {
            NSMutableArray *upgradeArray = [_managedQueue[@"Upgrade"] mutableCopy];
            [upgradeArray removeObject:package];
            [_managedQueue setObject:upgradeArray forKey:@"Upgrade"];
            break;
        }
    }
}

- (NSArray *)tasks:(NSArray *)debs {
    NSMutableArray<NSArray *> *commands = [NSMutableArray new];
    NSArray *baseCommand = @[@"dpkg"];
    
    NSMutableArray *installArray = [_managedQueue[@"Install"] mutableCopy];
    NSMutableArray *removeArray = [_managedQueue[@"Remove"] mutableCopy];
    NSMutableArray *reinstallArray = [_managedQueue[@"Reinstall"] mutableCopy];
    NSMutableArray *upgradeArray = [_managedQueue[@"Upgrade"] mutableCopy];
    
    if ([installArray count] > 0) {
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
    
    if ([removeArray count] > 0) {
        [commands addObject:@[@1]];
        NSMutableArray *removeCommand = [baseCommand mutableCopy];
        
        [removeCommand insertObject:@"-r" atIndex:1];
        for (ZBPackage *package in removeArray) {
            [removeCommand insertObject:[package identifier] atIndex:2];
        }
        
        [commands addObject:removeCommand];
    }
    
    if ([reinstallArray count] > 0) {
        [commands addObject:@[@2]];
        
        //Remove package first
        NSMutableArray *removeCommand = [baseCommand mutableCopy];
        
        [removeCommand insertObject:@"-r" atIndex:1];
        for (ZBPackage *package in reinstallArray) {
            [removeCommand insertObject:[package identifier] atIndex:2];
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
    
    if ([upgradeArray count] > 0) {
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
    switch (queue) {
        case ZBQueueTypeInstall: {
            return [_managedQueue[@"Install"] objectAtIndex:index];
        }
        case ZBQueueTypeRemove: {
            return [_managedQueue[@"Remove"] objectAtIndex:index];
        }
        case ZBQueueTypeReinstall: {
            return [_managedQueue[@"Reinstall"] objectAtIndex:index];
        }
        case ZBQueueTypeUpgrade: {
            return [_managedQueue[@"Upgrade"] objectAtIndex:index];
        }
    }
}

- (void)clearQueue {
    _managedQueue = [NSMutableDictionary new];
    [_managedQueue setObject:@[] forKey:@"Install"];
    [_managedQueue setObject:@[] forKey:@"Remove"];
    [_managedQueue setObject:@[] forKey:@"Reinstall"];
    [_managedQueue setObject:@[] forKey:@"Upgrade"];
    
    _failedDepQueue = [NSMutableArray new];
    _failedConQueue = [NSMutableArray new];
}

- (NSArray *)actionsToPerform {
    NSMutableArray *actions = [NSMutableArray new];
    
    if ([_failedDepQueue count] > 0) {
        [actions addObject:@"Unresolved Dependencies"];
    }
    
    if ([_failedConQueue count] > 0) {
        [actions addObject:@"Conflictions"];
    }
    
    if ([_managedQueue[@"Install"] count] > 0) {
        [actions addObject:@"Install"];
    }
    
    if ([_managedQueue[@"Remove"] count] > 0) {
        [actions addObject:@"Remove"];
    }
    
    if ([_managedQueue[@"Reinstall"] count] > 0) {
        [actions addObject:@"Reinstall"];
    }
    
    if ([_managedQueue[@"Upgrade"] count] > 0) {
        [actions addObject:@"Upgrade"];
    }
    
    return (NSArray *)actions;
}

- (BOOL)hasObjects {
    if ([_managedQueue[@"Install"] count] > 0) {
        return true;
    }
    
    if ([_managedQueue[@"Remove"] count] > 0) {
        return true;
    }
    
    if ([_managedQueue[@"Reinstall"] count] > 0) {
        return true;
    }
    
    if ([_managedQueue[@"Upgrade"] count] > 0) {
        return true;
    }
    
    return false;
}

- (BOOL)containsPackage:(ZBPackage *)package {
    if ([_managedQueue[@"Install"] containsObject:package]) {
        return true;
    }
    
    if ([_managedQueue[@"Remove"] containsObject:package]) {
        return true;
    }
    
    if ([_managedQueue[@"Reinstall"] containsObject:package]) {
        return true;
    }
    
    if ([_managedQueue[@"Upgrade"] containsObject:package]) {
        return true;
    }
    
    return false;
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
    
    [packages addObjectsFromArray:_managedQueue[@"Install"]];
    [packages addObjectsFromArray:_managedQueue[@"Reinstall"]];
    [packages addObjectsFromArray:_managedQueue[@"Upgrade"]];
    
    return (NSArray *)packages;
}

- (BOOL)needsHyena {
    if ([_managedQueue[@"Install"] count] > 0) {
        return true;
    }
    
    if ([_managedQueue[@"Reinstall"] count] > 0) {
        return true;
    }
    
    if ([_managedQueue[@"Upgrade"] count] > 0) {
        return true;
    }
    
    return false;
}

@end
