//
//  ZBDependencyResolver.m
//  Zebra
//
//  Created by Wilson Styres on 3/26/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBDependencyResolver.h"
#import "ZBDatabaseManager.h"
#import <Packages/Helpers/ZBPackage.h>
#import <ZBAppDelegate.h>
#import <sqlite3.h>
#import <Queue/ZBQueue.h>

@implementation ZBDependencyResolver

@synthesize databaseManager;
@synthesize queue;
@synthesize database;

- (id)init {
    self = [super init];
    
    if (self) {
        databaseManager = [[ZBDatabaseManager alloc] init];
        queue = [ZBQueue sharedInstance];
        
        sqlite3_open([[ZBAppDelegate databaseLocation] UTF8String], &database);
    }
    
    return self;
}

- (void)addDependenciesForPackage:(ZBPackage *)package {
    if ([databaseManager packageIsInstalled:package inDatabase:database]) {
        NSLog(@"%@ (%@) is already installed, dependencies resolved.", [package name], [package identifier]);
        return;
    }
    
    NSArray *dependencies = [package dependsOn];
    
    for (NSString *line in dependencies) {
        ZBPackage *depPackage = [self packageThatResolvesDependency:line];
        if (depPackage != NULL && [depPackage name] != NULL) { //Dependency found, all gucci
            [queue addPackage:depPackage toQueue:ZBQueueTypeInstall];
        }
        else if ([queue containsPackage:package inQueue:ZBQueueTypeInstall] || ([depPackage name] != NULL || [depPackage installed])) { //Package is installed, don't need to resolve any further
            continue;
        }
        else { //Failed to find dependency
            NSLog(@"Failed to find dependency for %@ to match %@", package, line);
            [queue markPackageAsFailed:package forDependency:line];
            return;
        }
    }
}

- (ZBPackage *)packageThatResolvesDependency:(NSString *)line {
    NSLog(@"Package that resolves dependenct %@", line);
    ZBPackage *package;
    if ([line rangeOfString:@" | "].location != NSNotFound) {
        package = [self packageThatSatisfiesORComparison:line];
    }
    else if ([line rangeOfString:@"("].location != NSNotFound && [line rangeOfString:@")"].location != NSNotFound) {
        package = [self packageThatSatisfiesVersionComparison:line];
    }
    else {
        NSString *depPackageID = line;
        package = [databaseManager packageForID:depPackageID thatSatisfiesComparison:NULL ofVersion:NULL inDatabase:database];
    }
    
    if (package == NULL)
        return NULL;
    
    if ([databaseManager packageIsInstalled:package inDatabase:database]) {
        NSLog(@"%@ is already installed, skipping", [package identifier]);
        ZBPackage *installed = [[ZBPackage alloc] init];
        installed.installed = true;
        return installed; //This could probably done a little better...
    }
    
    return package;
}

- (ZBPackage *)packageThatSatisfiesORComparison:(NSString *)line {
    NSArray *comps = [line componentsSeparatedByString:@" | "];
    for (NSString *depPackageID in comps) {
        NSLog(@"Comp line %@", depPackageID);
        ZBPackage *depPackage = [self packageThatResolvesDependency:depPackageID];
        
        if (depPackage != NULL) {
            return depPackage;
        }
    }
    return NULL;
}

- (ZBPackage *)packageThatSatisfiesVersionComparison:(NSString *)line {
    NSArray *components = [line componentsSeparatedByString:@" ("];
    NSString *depPackageID = components[0];
    NSArray *separate = [components[1] componentsSeparatedByString:@" "];
    NSString *comparison = separate[0];
    NSString *version = [separate[1] substringToIndex:[separate[1] length] - 1];
    
    NSLog(@"Trying to resolve version, %@ needs to be %@ than %@", depPackageID, comparison, version);
    
    return [databaseManager packageForID:depPackageID thatSatisfiesComparison:comparison ofVersion:version inDatabase:database];
}

//- (NSArray *)getDependenciesForPackage:(ZBPackage *)package alreadyQueued:(NSArray *)qd {
//    NSMutableArray *queued = [qd mutableCopy];
//
//    NSArray *dependencies = [package dependsOn];
//    NSLog(@"Depends On: %@", dependencies);
//
//    for (NSString *line in dependencies) {
//        NSArray *comps = [line componentsSeparatedByString:@" | "]; //Separates OR requirements
//
//
//        if ([comps count] > 1) {
//            for (NSString *dPID in comps) {
//                NSArray *version = [dPID componentsSeparatedByString:@" ("];
//                if ([version count] > 1) { //Try to resolve version dependency
//                    NSString *depPackageID = version[0];
//                    NSArray *separate = [version[1] componentsSeparatedByString:@" "];
//                    NSString *comparison = separate[0];
//                    NSString *version = [separate[1] substringToIndex:[separate[1] length] - 1];
//
//                    NSLog(@"Trying to resolve version, %@ needs to be %@ than %@", depPackageID, comparison, version);
//
//                    ZBPackage *depPackage = [databaseManager packageForID:depPackageID thatSatisfiesComparison:comparison ofVersion:version inDatabase:database];
//
//                    NSLog(@"Resolved dependency for %@ needs to be %@ than %@: %@", depPackageID, comparison, version, depPackage);
//
//                    if ([queued containsObject:depPackage]) {
//                        NSLog(@"%@ is already queued, skipping", depPackageID);
//                        continue;
//                    }
//
//                    if ([databaseManager packageIsInstalled:[depPackage identifier] inDatabase:database]) {
//                        NSLog(@"%@ is already installed, skipping", [depPackage identifier]);
//                        continue;
//                    }
//                    else if ([databaseManager packageIsAvailable:[depPackage identifier] inDatabase:database]) {
//                        NSLog(@"%@ is available, adding it to queued packages", [depPackage identifier]);
//                        if (![queued containsObject:depPackage]) {
//                            [queued addObject:depPackage];
//
//                            NSArray *depsForDep = [self getDependenciesForPackage:depPackage alreadyQueued:queued];
//                            for (ZBPackage *dep in depsForDep) {
//                                if (![queued containsObject:dep]) {
//                                    [queued addObject:dep];
//                                }
//                            }
//                            continue;
//                        }
//                        else {
//                            NSLog(@"%@ is already queued (2), skipping", [depPackage identifier]);
//                            continue;
//                        }
//
//
//                    }
//                    else {
//                        NSLog(@"Cannot resolve dependencies for %@ because %@ cannot be found", [package identifier], depPackageID);
//                        continue;
//                    }
//                }
//                else {
//                    NSString *depPackageID = version[0];
//                    NSLog(@"Comp line %@", depPackageID);
//                    ZBPackage *depPackage = [databaseManager packageForID:depPackageID thatSatisfiesComparison:NULL ofVersion:NULL inDatabase:database];
//
//                    if ([queued containsObject:depPackage]) {
//                        NSLog(@"%@ is already queued, skipping", depPackageID);
//                        break;
//                    }
//
//                    if ([databaseManager packageIsInstalled:[depPackage identifier] inDatabase:database]) {
//                        NSLog(@"%@ is already installed, skipping", [depPackage identifier]);
//                        break;
//                    }
//                    else if ([databaseManager packageIsAvailable:[depPackage identifier] inDatabase:database]) {
//                        NSLog(@"%@ is available, adding it to queued packages", [depPackage identifier]);
//                        if (![queued containsObject:depPackage]) {
//                            [queued addObject:depPackage];
//
//                            NSArray *depsForDep = [self getDependenciesForPackage:depPackage alreadyQueued:queued];
//                            for (ZBPackage *dep in depsForDep) {
//                                if (![queued containsObject:dep]) {
//                                    [queued addObject:dep];
//                                }
//                            }
//                            break;
//                        }
//                        else {
//                            NSLog(@"%@ is already queued (2), skipping", [depPackage identifier]);
//                            break;
//                        }
//
//
//                    }
//                    else {
//                        NSLog(@"Cannot resolve dependencies for %@ because %@ cannot be found", [package identifier], depPackageID);
//                        continue;
//                    }
//                }
//            }
//        }
//        else { //Continue about your business
//            NSArray *version = [comps[0] componentsSeparatedByString:@" ("];
//            if ([version count] > 1) { //Try to resolve version dependency
//                NSString *depPackageID = version[0];
//                NSArray *separate = [version[1] componentsSeparatedByString:@" "];
//                NSString *comparison = separate[0];
//                NSString *version = [separate[1] substringToIndex:[separate[1] length] - 1];
//
//                NSLog(@"Trying to resolve version, %@ needs to be %@ than %@", depPackageID, comparison, version);
//
//                ZBPackage *depPackage = [databaseManager packageForID:depPackageID thatSatisfiesComparison:comparison ofVersion:version inDatabase:database];
//
//                NSLog(@"Resolved dependency for %@ needs to be %@ than %@: %@", depPackageID, comparison, version, depPackage);
//
//                if ([queued containsObject:depPackage]) {
//                    NSLog(@"%@ is already queued, skipping", depPackageID);
//                    continue;
//                }
//
//                if ([databaseManager packageIsInstalled:[depPackage identifier] inDatabase:database]) {
//                    NSLog(@"%@ is already installed, skipping", [depPackage identifier]);
//                    continue;
//                }
//                else if ([databaseManager packageIsAvailable:[depPackage identifier] inDatabase:database]) {
//                    NSLog(@"%@ is available, adding it to queued packages", [depPackage identifier]);
//                    if (![queued containsObject:depPackage]) {
//                        [queued addObject:depPackage];
//
//                        NSArray *depsForDep = [self getDependenciesForPackage:depPackage alreadyQueued:queued];
//                        for (ZBPackage *dep in depsForDep) {
//                            if (![queued containsObject:dep]) {
//                                [queued addObject:dep];
//                            }
//                        }
//                        continue;
//                    }
//                    else {
//                        NSLog(@"%@ is already queued (2), skipping", [depPackage identifier]);
//                        continue;
//                    }
//
//
//                }
//                else {
//                    NSLog(@"Cannot resolve dependencies for %@ because %@ cannot be found", [package identifier], depPackageID);
//                    continue;
//                }
//            }
//            else {
//                NSString *depPackageID = version[0];
//                ZBPackage *depPackage = [databaseManager packageForID:depPackageID thatSatisfiesComparison:NULL ofVersion:NULL inDatabase:database];
//
//                if ([queued containsObject:depPackage]) {
//                    NSLog(@"%@ is already queued, skipping", depPackageID);
//                    continue;
//                }
//
//                if ([databaseManager packageIsInstalled:[depPackage identifier] inDatabase:database]) {
//                    NSLog(@"%@ is already installed, skipping", [depPackage identifier]);
//                    continue;
//                }
//                else if ([databaseManager packageIsAvailable:[depPackage identifier] inDatabase:database]) {
//                    NSLog(@"%@ is available, adding it to queued packages", [depPackage identifier]);
//                    if (![queued containsObject:depPackage]) {
//                        [queued addObject:depPackage];
//
//                        NSArray *depsForDep = [self getDependenciesForPackage:depPackage alreadyQueued:queued];
//                        for (ZBPackage *dep in depsForDep) {
//                            if (![queued containsObject:dep]) {
//                                [queued addObject:dep];
//                            }
//                        }
//                    }
//                    else {
//                        NSLog(@"%@ is already queued (2), skipping", [depPackage identifier]);
//                    }
//
//
//                }
//                else {
//                    NSLog(@"Cannot resolve dependencies for %@ because %@ cannot be found", [package identifier], depPackageID);
//                }
//            }
//        }
//
//    }
//
//    return queued;
//}

@end
