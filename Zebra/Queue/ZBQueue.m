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
#import <ZBDevice.h>
#import <Console/ZBStage.h>

@interface ZBQueue ()
@property (nonatomic, strong) NSMutableArray<NSString *> *queuedPackagesList;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray <ZBPackage *> *> *managedQueue;
@end

@implementation ZBQueue

@synthesize managedQueue;
@synthesize queuedPackagesList;

+ (id)sharedQueue {
    static ZBQueue *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBQueue new];
    });
    return instance;
}

+ (int)count {
    int numberOfPackages = 0;
    for (NSArray *queue in [[self sharedQueue] queues]) {
        numberOfPackages += [queue count];
    }
    numberOfPackages += [[[self sharedQueue] dependencyQueue] count]; //dependencyQueue is not a member of [self queues]
    numberOfPackages += [[[self sharedQueue] conflictQueue] count]; //conflictQueue is not a member of [self queues]
    return numberOfPackages;
}

- (id)init {
    self = [super init];
    
    if (self) {
        managedQueue = [NSMutableDictionary new];
        for (ZBQueueType q = ZBQueueTypeInstall; q <= ZBQueueTypeDependency; q <<= 1) {
            [managedQueue setObject:[NSMutableArray new] forKey:@(q)];
        }
        queuedPackagesList = [NSMutableArray new];
    }
    
    return self;
}

- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue {
    ZBQueueType type = [self locate:package];
    if (type != ZBQueueTypeClear && type != queue) { //Remove package from queue
        [[self queueFromType:type] removeObject:package];
    }
    if (type != queue) {
        [[self queueFromType:queue] addObject:package];
        [queuedPackagesList addObject:[package identifier]];
        if (queue == ZBQueueTypeInstall || queue == ZBQueueTypeUpgrade || queue == ZBQueueTypeDowngrade) {
            NSLog(@"[Zebra] Finding dependencies for %@", package);
            if ([self enqueueDependenciesForPackage:package]) {
                NSLog(@"[Zebra] All dependencies found for %@", package);
            }
            else {
                NSLog(@"[Zebra] Unable to find all dependencies for %@", package);
            }
        }
        else if (queue == ZBQueueTypeRemove) {
            NSLog(@"[Zebra] Removing packages that depend on %@", package);
            [self enqueueRemovalOfPackagesThatDependOn:package];
        }
    }
}

- (void)addPackages:(NSArray <ZBPackage *> *)packages toQueue:(ZBQueueType)queue {
    for (ZBPackage *package in packages) {
        [self addPackage:package toQueue:queue];;
    }
}

- (void)addDependency:(ZBPackage *)package {
    if (![[self dependencyQueue] containsObject:package]) {
        [queuedPackagesList addObject:[package identifier]];
        for (NSString *providedPackage in [package provides]) {
            NSArray *components = [providedPackage componentsSeparatedByString:@"("];
            NSString *packageID = [components[0] stringByReplacingOccurrencesOfString:@" " withString:@""];
            [queuedPackagesList addObject:packageID];
        }
        
        [[self dependencyQueue] addObject:package];
    }
}

- (void)addConflict:(ZBPackage *)package {
    if (![[self conflictQueue] containsObject:package]) {
        [[self conflictQueue] addObject:package];
        [self enqueueRemovalOfPackagesThatDependOn:package];
    }
}

- (BOOL)enqueueDependenciesForPackage:(ZBPackage *)package {
    ZBDependencyResolver *resolver = [[ZBDependencyResolver alloc] initWithPackage:package];
    return [resolver immediateResolution];
}

- (void)enqueueRemovalOfPackagesThatDependOn:(ZBPackage *)package {
    [self addPackages:[[ZBDatabaseManager sharedInstance] packagesThatDependOn:package] toQueue:ZBQueueTypeRemove];
}

- (void)removePackage:(ZBPackage *)package {
    ZBQueueType action = [self locate:package];
    if (action == ZBQueueTypeRemove) {
        ZBPackage *topPackage = package;
        while ([topPackage removedBy] != NULL) {
            topPackage = [topPackage removedBy];
        }
        [self removePackage:topPackage inQueue:ZBQueueTypeRemove];
        [self removePackagesRemovedBy:topPackage];
        return;
    }
    else if (action != ZBQueueTypeClear) {
        [self removePackage:package inQueue:action];
        for (ZBPackage *dependency in [package dependencies]) {
            [[dependency dependencyOf] removeObject:package];
            if ([[dependency dependencyOf] count] <= 1) {
                [self removePackage:dependency];
            }
        }
        for (ZBPackage *dependencyOf in [package dependencyOf]) {
            [[dependencyOf dependencies] removeObject:package];
            [self removePackage:dependencyOf];
        }
    }
}

- (void)removePackage:(ZBPackage *)package inQueue:(ZBQueueType)queue {
    [[package issues] removeAllObjects];
    [package setRemovedBy:NULL];
    [[self queueFromType:queue] removeObject:package];
}

- (void)removePackagesRemovedBy:(ZBPackage *)package {
    for (ZBPackage *removedPackage in [[self removeQueue] copy]) {
        if ([[removedPackage removedBy] isEqual:package]) {
            [self removePackage:removedPackage inQueue:ZBQueueTypeRemove];
            [self removePackagesRemovedBy:removedPackage];
        }
    }
}

- (void)clear {
    for (NSMutableArray *array in [self queues]) {
        [array removeAllObjects];
    }
    [[self dependencyQueue] removeAllObjects];
    [[self conflictQueue] removeAllObjects];
    [queuedPackagesList removeAllObjects];
}

- (NSArray *)tasksToPerform:(NSArray <NSDictionary <NSString*, NSString *> *> *)debs {
    NSMutableArray<NSArray *> *commands = [NSMutableArray new];
    NSArray *baseCommand;
    if ([[ZBDevice packageManagementBinary] isEqualToString:@"/usr/bin/apt"]) {
        baseCommand = @[@"apt", @"-yqf", @"--allow-downgrades", @"-oApt::Get::HideAutoRemove=true", @"-oquiet::NoProgress=true", @"-oquiet::NoStatistic=true"];
    }
    else if ([[ZBDevice packageManagementBinary] isEqualToString:@"/usr/bin/dpkg"]) {
        baseCommand = @[@"dpkg"];
    }
    else {
        return NULL;
    }
    
    NSString *binary = baseCommand[0];

    if ([self queueHasPackages:ZBQueueTypeRemove]) {
        NSMutableArray *removeCommand = [baseCommand mutableCopy];
        if ([binary isEqualToString:@"apt"]) {
            [removeCommand addObject:@"remove"];
        }
        else {
            [removeCommand addObject:@"-r"];
        }
        
        for (ZBPackage *package in [self removeQueue]) {
            [removeCommand addObject:package.identifier];
        }
        
        for (ZBPackage *package in [self conflictQueue]) {
            [removeCommand addObject:package.identifier];
        }
        
        [commands addObject:@[@(ZBStageRemove)]];
        [commands addObject:removeCommand];
    }
    
    if ([self queueHasPackages:ZBQueueTypeInstall]) {
        NSMutableArray *installCommand = [baseCommand mutableCopy];
        if ([binary isEqualToString:@"apt"]) {
            [installCommand addObject:@"install"];
        }
        else {
            [installCommand addObject:@"-i"];
        }
        
        NSArray *paths = [self pathsForDownloadedDebsInQueue:ZBQueueTypeInstall filenames:debs];
        [installCommand addObjectsFromArray:paths];
        
        [commands addObject:@[@(ZBStageInstall)]];
        [commands addObject:installCommand];
    }
    
    if ([self queueHasPackages:ZBQueueTypeReinstall]) {
        [commands addObject:@[@(ZBStageReinstall)]];
        if ([binary isEqualToString:@"apt"]) {
            NSMutableArray *reinstallCommand = [baseCommand mutableCopy];
            [reinstallCommand addObject:@"install"];
            [reinstallCommand addObject:@"--reinstall"];
            
            NSArray *paths = [self pathsForDownloadedDebsInQueue:ZBQueueTypeReinstall filenames:debs];
            [reinstallCommand addObjectsFromArray:paths];
            [commands addObject:reinstallCommand];
        }
        else if ([binary isEqualToString:@"dpkg"]) {
            //Remove package first
            NSMutableArray *removeCommand = [baseCommand mutableCopy];
            
            [removeCommand insertObject:@"-r" atIndex:1];
            [removeCommand insertObject:@"--force-depends" atIndex:2];
            for (ZBPackage *package in [self reinstallQueue]) {
                [removeCommand addObject:package.identifier];
            }
            [commands addObject:removeCommand];
            
            //Install new version
            NSMutableArray *installCommand = [baseCommand mutableCopy];
            [installCommand insertObject:@"-i" atIndex:1];
            NSArray *paths = [self pathsForDownloadedDebsInQueue:ZBQueueTypeReinstall filenames:debs];
            [installCommand addObjectsFromArray:paths];
            [commands addObject:installCommand];
        }
    }
    
    if ([self queueHasPackages:ZBQueueTypeUpgrade]) {
        NSMutableArray *upgradeCommand = [baseCommand mutableCopy];
        if ([binary isEqualToString:@"apt"]) {
            [upgradeCommand addObject:@"install"];
        }
        else {
            [upgradeCommand addObject:@"-i"];
        }
        
        NSArray *paths = [self pathsForDownloadedDebsInQueue:ZBQueueTypeUpgrade filenames:debs];
        [upgradeCommand addObjectsFromArray:paths];

        [commands addObject:@[@(ZBStageUpgrade)]];
        [commands addObject:upgradeCommand];
    }
    
    if ([self queueHasPackages:ZBQueueTypeDowngrade]) {
        NSMutableArray *downgradeCommand = [baseCommand mutableCopy];
        if ([binary isEqualToString:@"apt"]) {
            [downgradeCommand addObject:@"install"];
        }
        else {
            [downgradeCommand addObject:@"-i"];
        }
        
        NSArray *paths = [self pathsForDownloadedDebsInQueue:ZBQueueTypeDowngrade filenames:debs];
        [downgradeCommand addObjectsFromArray:paths];

        [commands addObject:@[@(ZBStageDowngrade)]];
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
    return managedQueue[@(queue)];
}

- (BOOL)queueHasPackages:(ZBQueueType)queue {
    if (queue == ZBQueueTypeRemove) {
        return [managedQueue[@(queue)] count] > 0 || [[self conflictQueue] count] > 0;
    }
    else if (queue == ZBQueueTypeInstall) {
        return [managedQueue[@(queue)] count] > 0 || [[self dependencyQueue] count] > 0;
    }
    else {
        return [managedQueue[@(queue)] count] > 0;
    }
}

- (NSString *)displayableNameForQueueType:(ZBQueueType)queue useIcon:(BOOL)icon {
    BOOL useIcon = icon ? [ZBDevice useIcon] : false;
    
    switch (queue) {
        case ZBQueueTypeInstall:
            return useIcon ? @"↓" : NSLocalizedString(@"Install", @"");
        case ZBQueueTypeReinstall:
            return useIcon ? @"↺" : NSLocalizedString(@"Reinstall", @"");
        case ZBQueueTypeRemove:
            return useIcon ? @"╳" : NSLocalizedString(@"Remove", @"");
        case ZBQueueTypeUpgrade:
            return useIcon ? @"↑" : NSLocalizedString(@"Upgrade", @"");
        case ZBQueueTypeDowngrade:
            return useIcon ? @"⇵" : NSLocalizedString(@"Downgrade", @"");
        default:
            break;
    }
    return @"This shouldn't be here...";
}

- (NSArray<NSNumber *> *)actionsToPerform {
    NSMutableArray *actions = [NSMutableArray new];
    
    for (ZBQueueType q = ZBQueueTypeInstall; q <= ZBQueueTypeDowngrade; q <<= 1) {
        if(
           managedQueue[@(q)].count > 0
           || (q == ZBQueueTypeInstall && [self dependencyQueue].count > 0)
           || (q == ZBQueueTypeRemove && [self conflictQueue].count > 0)
        ) {
            [actions addObject:@(q)];
        }
    }

    return actions;
}

- (int)numberOfPackagesInQueue:(ZBQueueType)queue {
    return (int)[managedQueue[@(queue)] count];
}

- (BOOL)needsToDownloadPackages {
    for (NSNumber *key in managedQueue) {
        if (key.intValue != ZBQueueTypeRemove && [managedQueue[key] count] > 0) {
            return YES;
        }
    }
    
    return NO;
}

- (NSArray *)packagesToDownload {
    NSMutableArray *packages = [NSMutableArray new];
    for (NSNumber *key in managedQueue) {
        if (key.intValue != ZBQueueTypeRemove) {
            [packages addObjectsFromArray:managedQueue[key]];
        }
    }
    
    return (NSArray *)packages;
}

- (BOOL)contains:(ZBPackage *)package {
    if ([queuedPackagesList containsObject:[package identifier]]) {
        return true;
    }
    
    for (NSNumber *key in managedQueue) {
        if ([managedQueue[key] containsObject:package]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)contains:(ZBPackage *)package inQueue:(ZBQueueType)queue {
    if (queue == ZBQueueTypeClear || queue == 0) {
        return [self contains:package];
    }
    else {
        NSMutableArray *queueArray = [self queueFromType:queue];
        if (!queueArray) return NO;
        for (ZBPackage *p in queueArray) {
            if ([p isEqual:package]) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSArray <NSString *> *)queuedPackagesList {
    return queuedPackagesList;
}

- (NSArray <NSArray <ZBPackage *> *> *)topDownQueue {
    NSMutableArray *result = [NSMutableArray new];
    for (NSArray *queueArray in [self queues]) {
        NSMutableArray *topDownQueue = [queueArray mutableCopy];

        if(queueArray == [self installQueue]) {
            [topDownQueue addObjectsFromArray:[self dependencyQueue]];
        } else if(queueArray == [self removeQueue]) {
            [topDownQueue addObjectsFromArray:[self conflictQueue]];
        }

        if(topDownQueue.count > 0) {
            [result addObject:topDownQueue];
        }
    }
    return result;
}

- (void)allDependenciesForPackage:(ZBPackage *)package dependencies:(NSMutableArray *)array {
    if (![array containsObject:package]) {
        [array addObject:package];
        for (ZBPackage *dependency in [package dependencies]) {
            [self allDependenciesForPackage:dependency dependencies:array];
        }
    }
}

- (NSString *)downloadSizeForQueue:(ZBQueueType)queueType {
    double totalDownloadSize = 0;
    NSMutableArray *packages = [[self queueFromType:queueType] mutableCopy];
    if (queueType == ZBQueueTypeInstall) {
        [packages addObjectsFromArray:[self dependencyQueue]];
    }
    
    for (ZBPackage *package in packages) {
        totalDownloadSize += [package numericSize];
    }
    if (totalDownloadSize) {
        NSString *unit = @"bytes";
        if (totalDownloadSize > 1024 * 1024) {
            totalDownloadSize /= 1024 * 1024;
            unit = @"MB";
        }
        else if (totalDownloadSize > 1024) {
            totalDownloadSize /= 1024;
            unit = @"KB";
        }
        return [NSString stringWithFormat:@"%.2f %@", totalDownloadSize, unit];
    }
    
    return NULL;
}

- (ZBQueueType)locate:(ZBPackage *)package {
    for (NSNumber *key in managedQueue) {
        if ([managedQueue[key] containsObject:package]) {
            return key.intValue;
        }
    }
    
    return ZBQueueTypeClear;
}

- (BOOL)hasIssues {
    return [[self issues] count];
}

- (NSArray <NSArray <NSString *> *> *)issues {
    NSMutableArray *issues = [NSMutableArray new];
    NSArray *topDownQueue = [self topDownQueue];
    for (NSArray *queueArray in topDownQueue) {
        for (ZBPackage *package in queueArray) {
            if ([package hasIssues]) {
                [issues addObjectsFromArray:[package issues]];
            }
        }
    }
    return issues;
}

- (NSArray <NSMutableArray *> *)queues {
    return @[[self installQueue], [self reinstallQueue], [self removeQueue], [self upgradeQueue], [self downgradeQueue]];
}

- (NSMutableArray *)installQueue {
    return managedQueue[@(ZBQueueTypeInstall)];
}

- (NSMutableArray *)reinstallQueue {
    return managedQueue[@(ZBQueueTypeReinstall)];
}

- (NSMutableArray *)removeQueue {
    return managedQueue[@(ZBQueueTypeRemove)];
}

- (NSMutableArray *)upgradeQueue {
    return managedQueue[@(ZBQueueTypeUpgrade)];
}

- (NSMutableArray *)downgradeQueue {
    return managedQueue[@(ZBQueueTypeDowngrade)];
}

- (NSMutableArray *)dependencyQueue {
    return managedQueue[@(ZBQueueTypeDependency)];
}

- (NSMutableArray *)conflictQueue {
    return managedQueue[@(ZBQueueTypeConflict)];
}

@end
