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

@interface ZBQueue ()
@property (nonatomic, strong) NSMutableArray<NSString *> *queuedPackagesList;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray <ZBPackage *> *> *managedQueue;
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
    return numberOfPackages;
}

- (id)init {
    self = [super init];
    
    if (self) {
        managedQueue = [NSMutableDictionary new];
        for (ZBQueueType q = ZBQueueTypeInstall; q <= ZBQueueTypeDependency; q <<= 1) {
            [managedQueue setObject:[NSMutableArray new] forKey:[self keyFromQueueType:q]];
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

- (BOOL)enqueueDependenciesForPackage:(ZBPackage *)package {
    ZBDependencyResolver *resolver = [[ZBDependencyResolver alloc] initWithPackage:package];
    return [resolver calculateDependencies];
}

- (void)enqueueRemovalOfPackagesThatDependOn:(ZBPackage *)package {
    [self addPackages:[[ZBDatabaseManager sharedInstance] packagesThatDependOn:package] toQueue:ZBQueueTypeRemove];
}

- (void)removePackage:(ZBPackage *)package {
    ZBQueueType action = [self locate:package];
    if (action != ZBQueueTypeClear) {
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
    [[self queueFromType:queue] removeObject:package];
}

- (void)clear {
    for (NSMutableArray *array in [self queues]) {
        [array removeAllObjects];
    }
    [queuedPackagesList removeAllObjects];
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
        
        [commands addObject:@[@(ZBQueueTypeInstall)]];
        [commands addObject:installCommand];
    }
    
    if ([self queueHasPackages:ZBQueueTypeReinstall]) {
        NSMutableArray *reinstallCommand = [baseCommand mutableCopy];
        [reinstallCommand addObject:@"install"];
        [reinstallCommand addObject:@"--reinstall"];
        
        NSArray *paths = [self pathsForDownloadedDebsInQueue:ZBQueueTypeReinstall filenames:debs];
        [reinstallCommand addObjectsFromArray:paths];
        
        [commands addObject:@[@(ZBQueueTypeReinstall)]];
        [commands addObject:reinstallCommand];
    }
    
    if ([self queueHasPackages:ZBQueueTypeRemove]) {
        NSMutableArray *removeCommand = [baseCommand mutableCopy];
        [removeCommand addObject:@"remove"];
        
        for (ZBPackage *package in [self removeQueue]) {
            [removeCommand addObject:package.identifier];
        }
        
        [commands addObject:@[@(ZBQueueTypeRemove)]];
        [commands addObject:removeCommand];
    }
    
    if ([self queueHasPackages:ZBQueueTypeUpgrade]) {
        NSMutableArray *upgradeCommand = [baseCommand mutableCopy];
        [upgradeCommand addObject:@"install"];
        
        NSArray *paths = [self pathsForDownloadedDebsInQueue:ZBQueueTypeUpgrade filenames:debs];
        [upgradeCommand addObjectsFromArray:paths];

        [commands addObject:@[@(ZBQueueTypeUpgrade)]];
        [commands addObject:upgradeCommand];
    }
    
    if ([self queueHasPackages:ZBQueueTypeDowngrade]) {
        NSMutableArray *downgradeCommand = [baseCommand mutableCopy];
        [downgradeCommand addObject:@"install"];
        
        NSArray *paths = [self pathsForDownloadedDebsInQueue:ZBQueueTypeDowngrade filenames:debs];
        [downgradeCommand addObjectsFromArray:paths];

        [commands addObject:@[@(ZBQueueTypeDowngrade)]];
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
    NSArray *keys = @[@"install", @"reinstall", @"remove", @"upgrade", @"downgrade", @"dependency"];
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
        case 5:
            return ZBQueueTypeDependency;
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
        case ZBQueueTypeDependency:
            return @"dependency";
        default:
            break;
    }
    return NULL;
}

- (BOOL)queueHasPackages:(ZBQueueType)queue {
    return [managedQueue[[self keyFromQueueType:queue]] count] > 0;
}

- (NSString *)displayableNameForQueueType:(ZBQueueType)queue useIcon:(BOOL)icon {
    BOOL useIcon = icon ? [ZBDevice useIcon] : false;
    
    switch (queue) {
        case ZBQueueTypeInstall:
            return useIcon ? @"↓" : @"Install";
        case ZBQueueTypeReinstall:
            return useIcon ? @"↺" : @"Reinstall";
        case ZBQueueTypeRemove:
            return useIcon ? @"╳" : @"Remove";
        case ZBQueueTypeUpgrade:
            return useIcon ? @"↑" : @"Upgrade";
        case ZBQueueTypeDowngrade:
            return useIcon ? @"⇵" : @"Downgrade";
        default:
            break;
    }
    return @"This shouldn't be here...";
}

- (NSArray *)actionsToPerform {
    NSMutableArray *actions = [NSMutableArray new];
    if ([[self installQueue] count] > 0 || [[self dependencyQueue] count] > 0) {
        ZBQueueType type = ZBQueueTypeInstall;
        [actions addObject:[NSValue valueWithBytes:&type objCType:@encode(ZBQueueType)]];
    }
    if ([[self reinstallQueue] count] > 0) {
        ZBQueueType type = ZBQueueTypeReinstall;
        [actions addObject:[NSValue valueWithBytes:&type objCType:@encode(ZBQueueType)]];
    }
    if ([[self removeQueue] count] > 0) {
        ZBQueueType type = ZBQueueTypeRemove;
        [actions addObject:[NSValue valueWithBytes:&type objCType:@encode(ZBQueueType)]];
    }
    if ([[self upgradeQueue] count] > 0) {
        ZBQueueType type = ZBQueueTypeUpgrade;
        [actions addObject:[NSValue valueWithBytes:&type objCType:@encode(ZBQueueType)]];
    }
    if ([[self downgradeQueue] count] > 0) {
        ZBQueueType type = ZBQueueTypeDowngrade;
        [actions addObject:[NSValue valueWithBytes:&type objCType:@encode(ZBQueueType)]];
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

- (BOOL)contains:(ZBPackage *)package {
    if ([queuedPackagesList containsObject:[package identifier]]) {
        return true;
    }
    
    for (NSString *key in managedQueue) {
        if ([managedQueue[key] containsObject:package]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)contains:(ZBPackage *)package inQueue:(ZBQueueType)queue {
    if (queue == ZBQueueTypeClear)
        queue = 0;
    
    if (queue == 0) {
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
    for (NSArray *queue in [self queues]) {
        if ([queue count] > 0) {
            NSMutableArray *topDownQueue = [NSMutableArray new];
            for (ZBPackage *package in queue) {
                [topDownQueue addObject:package];
            }
            if (queue == [self installQueue]) {
                [topDownQueue addObjectsFromArray:[self dependencyQueue]];
            }
            [result addObject:topDownQueue];
        }
        else if (queue == [self installQueue] && [[self dependencyQueue] count] > 0) {
            NSMutableArray *topDownQueue = [NSMutableArray new];
            [topDownQueue addObjectsFromArray:[self dependencyQueue]];
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
    for (NSString *key in managedQueue) {
        if ([managedQueue[key] containsObject:package]) {
            return [self queueTypeFromKey:key];
        }
    }
    
    return ZBQueueTypeClear;
}

- (BOOL)hasIssues {
//    return false;
    return [[self issues] count] > 0;
}

- (NSArray <NSArray <NSString *> *> *)issues {
    NSMutableArray *issues = [NSMutableArray new];
    NSArray *topDownQueue = [self topDownQueue];
    for (NSArray *arr in topDownQueue) {
        for (ZBPackage *package in arr) {
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

- (NSMutableArray *)dependencyQueue {
    return managedQueue[[self keyFromQueueType:ZBQueueTypeDependency]];
}

@end
