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
#import <Repos/Helpers/ZBRepo.h>

@implementation ZBDependencyResolver

@synthesize databaseManager;
@synthesize queue;

- (id)init {
    self = [super init];
    
    if (self) {
        databaseManager = [ZBDatabaseManager sharedInstance];
        [databaseManager openDatabase];
        queue = [ZBQueue sharedInstance];
    }
    
    return self;
}

- (void)addDependenciesForPackage:(ZBPackage *)package {
    if ([databaseManager packageIsInstalled:package versionStrict:true]) {
//        NSLog(@"[Zebra] %@ (%@) is already installed, dependencies resolved.", [package name], [package identifier]);
        return;
    }
    
    NSArray *dependencies = [package dependsOn];
    
    for (NSString *line in dependencies) {
        ZBPackage *depPackage = [self packageThatResolvesDependency:line checkProvides:true];
        if (depPackage != NULL) {
            if ([databaseManager packageIsInstalled:depPackage versionStrict:true]) {
//                NSLog(@"[Zebra] %@ is already installed, skipping", [package identifier]);
                continue;
            }
            else if (![queue containsPackage:depPackage]) { //Dependency found, all gucci
//                NSLog(@"Resolved: %@", depPackage);
                [queue addPackage:depPackage toQueue:ZBQueueTypeInstall requiredBy:package];
            }
            else {
//                NSLog(@"[Zebra] %@ already in queue, skipping", [package identifier]);
                continue;
            }
        }
        else { //Failed to find dependency
//            NSLog(@"[Zebra] Failed to find dependency for %@ to match %@", package, line);
            [queue markPackageAsFailed:package forDependency:line];
            return;
        }
    }
}

- (ZBPackage *)packageThatResolvesDependency:(NSString *)line checkProvides:(BOOL)provides {
//    NSLog(@"[Zebra] Package that resolves dependency %@", line);
    ZBPackage *package = nil;
    if ([line rangeOfString:@" | "].location != NSNotFound) {
        package = [self packageThatSatisfiesORComparison:line checkProvides:provides];
    }
    else if ([line rangeOfString:@"("].location != NSNotFound && [line rangeOfString:@")"].location != NSNotFound) {
        package = [self packageThatSatisfiesVersionComparison:line checkProvides:provides];
    }
    else {
        NSString *depPackageID = line;
        package = [databaseManager packageForID:depPackageID thatSatisfiesComparison:NULL ofVersion:NULL checkInstalled:true checkProvides:provides];
    }
    
    return package;
}

- (ZBPackage *)packageThatSatisfiesORComparison:(NSString *)line checkProvides:(BOOL)provides {
    NSArray *comps = [line componentsSeparatedByString:@" | "];
    NSMutableArray *results = [NSMutableArray new];
    for (NSString *depPackageID in comps) {
        ZBPackage *depPackage = [self packageThatResolvesDependency:depPackageID checkProvides:provides];
        
        if (depPackage != NULL) {
            if ([databaseManager packageIsInstalled:depPackage versionStrict:false]) {
                return depPackage;
            }
            else {
                [results addObject:depPackage];
            }
        }
    }
    
    if ([results count]) {
        return results[0]; //The first one is probably fine
    }
    
    return NULL;
}

- (ZBPackage *)packageThatSatisfiesVersionComparison:(NSString *)line checkProvides:(BOOL)provides {
    NSArray *components = [line componentsSeparatedByString:@" ("];
    if ([components count] == 1) { //Bad package maker alert
        components = [line componentsSeparatedByString:@"("];
    }
    
    NSString *depPackageID = components[0];
    NSArray *separate = [components[1] componentsSeparatedByString:@" "];
    
    if ([separate count] > 1) {
        NSString *comparison = separate[0];
        NSString *version = [separate[1] substringToIndex:[separate[1] length] - 1];
        
//        NSLog(@"[Zebra] Trying to resolve version, %@ needs to be %@ than %@", depPackageID, comparison, version);
        return [databaseManager packageForID:depPackageID thatSatisfiesComparison:comparison ofVersion:version checkInstalled:true checkProvides:provides];
    }
    else { //bad repo maintainer alert
        NSString *versionComparison = [components[1] substringToIndex:[components[1] length] - 1];
        NSString *comparison;
        NSString *version;
        
        NSScanner *scanner = [NSScanner scannerWithString:versionComparison];
        NSCharacterSet *versionChars = [NSCharacterSet characterSetWithCharactersInString:@":.+-~abcdefghijklmnopqrstuvwxyz0123456789"];
        
        [scanner scanUpToCharactersFromSet:versionChars intoString:&comparison];
        [scanner scanCharactersFromSet:versionChars intoString:&version];
        
//        NSLog(@"[Zebra] Trying to resolve version, %@ needs to be %@ than %@", depPackageID, comparison, version);
        return [databaseManager packageForID:depPackageID thatSatisfiesComparison:comparison ofVersion:version checkInstalled:true checkProvides:provides];
    }
    
}

- (void)conflictionsWithPackage:(ZBPackage *)package state:(int)state {
    sqlite3 *database = [databaseManager database];
    if (state == 0) { //Installing package
        //First, check if package conflicts with any packages that are currently installed
        NSArray *conflictions = [package conflictsWith];
        
        for (NSString *line in conflictions) {
            ZBPackage *conf = [self packageThatResolvesDependency:line checkProvides:false];
            if (conf != NULL && [databaseManager packageIsInstalled:conf versionStrict:true]) {
                if ([[package provides] containsObject:conf.identifier] || [[package replaces] containsObject:conf.identifier]) {
                    // If this package can provide or replace this conflicting package, we can remove this conflicting package
                    // This also means, we have to install "package" first before we remove "conf"
                    [queue addPackage:conf toQueue:ZBQueueTypeRemove toTop:package];
                }
                else {
                    // Just remove this package
                    [queue addPackage:conf toQueue:ZBQueueTypeRemove];
                }
            }
        }
        
        //Then, check if any package that is installed conflicts with package
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE CONFLICTS LIKE \'%%%@\%%\' AND REPOID < 1;", [package identifier]];

        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *conf = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                for (NSString *dep in [conf conflictsWith]) {
                    if ([dep isEqualToString:package.identifier]) {
                        if ([[conf conflictsWith] containsObject:package.identifier]) {
                            // If this conflicting package (conf) conflicts with this not-installed package, we remove conf
                            [queue addPackage:conf toQueue:ZBQueueTypeRemove];
                            continue;
                        }
                        else if ([[conf provides] containsObject:package.identifier] || [[conf replaces] containsObject:package.identifier]) {
                            // If this conflicting package (conf) can replace this not-installed package, we don't have to install this package (package)
                            [queue removePackage:package fromQueue:ZBQueueTypeInstall];
                            continue;
                        }
                        [queue markPackageAsFailed:package forConflicts:conf conflictionType:1];
                    }
                }
            }
        }
        else {
            [databaseManager printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        //Now, check if this package replaces any other package, i.e., we will remove them
        
        NSArray *replaces = [package replaces];
        
        for (NSString *line in replaces) {
            ZBPackage *conf = [self packageThatResolvesDependency:line checkProvides:false];
            if (conf != NULL && [databaseManager packageIsInstalled:conf versionStrict:true]) {
                //                NSLog(@"%@ replaces %@, will remove %@", package, conf, conf);
                 [queue addPackage:conf toQueue:ZBQueueTypeRemove requiredBy:package];
            }
        }
        
    }
    else if (state == 1) { //Removing package
        //Check if any package that is installed depends on this package
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE DEPENDS LIKE \'%%%@\%%\' AND REPOID < 1;", [package identifier]];
        
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *dependingPackage = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                // Before we actually remove this package, it is possible that this package is to be removed due to its dependency being removed
                // If there is such other dependency that can provide, we should not remove this package
                BOOL shouldRemove = YES;
                for (NSString *line in [dependingPackage dependsOn]) {
                    ZBPackage *depPackage = [self packageThatResolvesDependency:line checkProvides:false];
                    if (depPackage) {
                        ZBPackage *providingPackage = [databaseManager packageThatProvides:depPackage.identifier checkInstalled:true];
                        if (providingPackage && ![providingPackage sameAs:depPackage]) {
                            shouldRemove = NO;
                            break;
                        }
                    }
                }
                if (shouldRemove) {
                    [queue addPackage:dependingPackage toQueue:ZBQueueTypeRemove requiredBy:package];
                }
            }
        }
        else {
            [databaseManager printDatabaseError];
        }
        sqlite3_finalize(statement);
    }
    else {
        NSLog(@"[Zebra] MY TIME HAS COME TO BURN");
    }
}

- (void)dealloc {
    [databaseManager closeDatabase];
}

@end
