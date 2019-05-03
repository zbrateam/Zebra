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
        ZBPackage *depPackage = [self packageThatResolvesDependency:line];
        if (depPackage != NULL) {
            if ([databaseManager packageIsInstalled:depPackage versionStrict:true]) {
//                NSLog(@"[Zebra] %@ is already installed, skipping", [package identifier]);
                continue;
            }
            else if (![queue containsPackage:depPackage]){ //Dependency found, all gucci
//                NSLog(@"Resolved: %@", depPackage);
                [queue addPackage:depPackage toQueue:ZBQueueTypeInstall];
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

- (ZBPackage *)packageThatResolvesDependency:(NSString *)line {
//    NSLog(@"[Zebra] Package that resolves dependency %@", line);
    ZBPackage *package;
    if ([line rangeOfString:@" | "].location != NSNotFound) {
        package = [self packageThatSatisfiesORComparison:line];
    }
    else if ([line rangeOfString:@"("].location != NSNotFound && [line rangeOfString:@")"].location != NSNotFound) {
        package = [self packageThatSatisfiesVersionComparison:line];
    }
    else {
        NSString *depPackageID = line;
        package = [databaseManager packageForID:depPackageID thatSatisfiesComparison:NULL ofVersion:NULL];
    }
    
    if (package == NULL)
        return NULL;
    
    return package;
}

- (ZBPackage *)packageThatSatisfiesORComparison:(NSString *)line {
    NSArray *comps = [line componentsSeparatedByString:@" | "];
    for (NSString *depPackageID in comps) {
        ZBPackage *depPackage = [self packageThatResolvesDependency:depPackageID];
        
        if (depPackage != NULL) {
            return depPackage;
        }
    }
    return NULL;
}

- (ZBPackage *)packageThatSatisfiesVersionComparison:(NSString *)line {
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
        return [databaseManager packageForID:depPackageID thatSatisfiesComparison:comparison ofVersion:version];
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
        return [databaseManager packageForID:depPackageID thatSatisfiesComparison:comparison ofVersion:version];
    }
    
}

//TODO: make this recursive
- (void)conflictionsWithPackage:(ZBPackage *)package state:(int)state {
    if (state == 0) { //Installing package
        //First, check if package conflicts with any packages that are currently installed
        NSArray *conflictions = [package conflictsWith];
        
        for (NSString *line in conflictions) {
            ZBPackage *conf = [self packageThatResolvesDependency:line];
            if (conf != NULL && [databaseManager packageIsInstalled:conf versionStrict:true]) {
//                NSLog(@"%@ conflicts with %@, cannot install %@", package, conf, package);
                [queue markPackageAsFailed:package forConflicts:conf conflictionType:0];
            }
        }
        
        //Then, check if any package that is installed conflicts with package
//        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE CONFLICTS LIKE \'%%%@\%%\' AND REPOID < 1;", [package identifier]];
//
//        sqlite3_stmt *statement;
//        sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
//        while (sqlite3_step(statement) == SQLITE_ROW) {
//            ZBPackage *conf = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//            for (NSString *dep in [conf conflictsWith]) {
//                if ([dep containsString:[package identifier]]) {
//                    [queue markPackageAsFailed:package forConflicts:conf conflictionType:1];
//                }
//            }
//        }
//        sqlite3_finalize(statement);
    }
    else if (state == 1) { //Removing package
        //Check if any package that is installed depends on this package
//        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE DEPENDS LIKE \'%%%@\%%\' AND REPOID < 1;", [package identifier]];
//        
//        sqlite3_stmt *statement;
//        sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
//        while (sqlite3_step(statement) == SQLITE_ROW) {
//            ZBPackage *conf = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//            for (NSString *dep in [conf dependsOn]) {
//                if ([dep containsString:[package identifier]]) {
//                    [queue markPackageAsFailed:package forConflicts:conf conflictionType:2];
//                }
//            }
//        }
//        sqlite3_finalize(statement);
    }
    else {
        NSLog(@"[Zebra] MY TIME HAS COME TO BURN");
    }
}

@end
