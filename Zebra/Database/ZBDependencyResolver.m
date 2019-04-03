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
        NSLog(@"[Zebra] %@ (%@) is already installed, dependencies resolved.", [package name], [package identifier]);
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
            NSLog(@"[Zebra] Failed to find dependency for %@ to match %@", package, line);
            [queue markPackageAsFailed:package forDependency:line];
            return;
        }
    }
}

- (ZBPackage *)packageThatResolvesDependency:(NSString *)line {
    NSLog(@"[Zebra] Package that resolves dependenct %@", line);
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
        NSLog(@"[Zebra] %@ is already installed, skipping", [package identifier]);
        ZBPackage *installed = [[ZBPackage alloc] init];
        installed.installed = true;
        return installed; //This could probably done a little better...
    }
    
    return package;
}

- (ZBPackage *)packageThatSatisfiesORComparison:(NSString *)line {
    NSArray *comps = [line componentsSeparatedByString:@" | "];
    for (NSString *depPackageID in comps) {
        NSLog(@"[Zebra] Comp line %@", depPackageID);
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
    
    NSLog(@"[Zebra] Trying to resolve version, %@ needs to be %@ than %@", depPackageID, comparison, version);
    
    return [databaseManager packageForID:depPackageID thatSatisfiesComparison:comparison ofVersion:version inDatabase:database];
}

@end
