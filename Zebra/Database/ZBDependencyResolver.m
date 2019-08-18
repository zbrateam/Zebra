//
//  ZBDependencyResolver.m
//  Zebra
//
//  Created by Wilson Styres on 3/26/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <ZBLog.h>
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
    if ([databaseManager packageIsInstalled:package versionStrict:YES]) {
        ZBLog(@"[Zebra] %@ has already been installed, dependencies resolved.", package);
        return;
    }
    
    NSArray *dependencies = [package dependsOn];
    
    for (NSString *line in dependencies) {
        ZBPackage *depPackage = [self packageThatResolvesDependency:line checkProvides:YES];
        if (depPackage != NULL) {
            if ([databaseManager packageIsInstalled:depPackage versionStrict:YES]) {
                ZBLog(@"[Zebra] %@ has already been installed, skipping", depPackage);
            } else {
                ZBPackage *providingPackage = [databaseManager packageThatProvides:depPackage.identifier checkInstalled:YES];
                if (providingPackage) {
                    // If there is an installed package that provides functionalities to this dependency package already, we don't need to install it
                    ZBLog(@"[Zebra] Removing %@ due to its alternative has already been installed", depPackage);
                    [queue removePackage:depPackage fromQueue:ZBQueueTypeInstall];
                } else if (![queue containsPackage:depPackage]) {
                    // Dependency can be added normally
                    ZBLog(@"[Zebra] Adding %@ to Install queue", depPackage);
                    [queue addPackage:depPackage toQueue:ZBQueueTypeInstall requiredBy:package];
                } else {
                    ZBLog(@"[Zebra] %@ already in queue, skipping", package);
                }
            }
        } else { // Failed to find dependency
            ZBLog(@"[Zebra] Failed to find dependency for %@ to match %@", package, line);
            [queue markPackageAsFailed:package forDependency:line];
            return;
        }
    }
}

- (ZBPackage *)packageThatResolvesDependency:(NSString *)line checkProvides:(BOOL)provides {
//    ZBLog(@"[Zebra] Package that resolves dependency %@", line);
    ZBPackage *package = nil;
    if ([line rangeOfString:@"|"].location != NSNotFound) {
        package = [self packageThatSatisfiesORComparison:line checkProvides:provides];
    } else if ([line rangeOfString:@"("].location != NSNotFound && [line rangeOfString:@")"].location != NSNotFound) {
        package = [self packageThatSatisfiesVersionComparison:line checkProvides:provides];
    } else {
        NSString *depPackageID = line;
        package = [databaseManager packageForID:depPackageID thatSatisfiesComparison:NULL ofVersion:NULL checkInstalled:YES checkProvides:provides];
    }
    
    return package;
}

- (ZBPackage *)packageThatSatisfiesORComparison:(NSString *)line checkProvides:(BOOL)provides {
    NSArray *comps = [line componentsSeparatedByString:@"|"];
    ZBLog(@"[Zebra] Extracted OR dependencies: %@", comps);
    NSMutableArray *results = [NSMutableArray new];
    for (NSString *depPackageID in comps) {
        NSString *trueDepPackageID = [depPackageID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        ZBPackage *depPackage = [self packageThatResolvesDependency:trueDepPackageID checkProvides:provides];
        ZBLog(@"[Zebra] Resolved OR dependency: %@ -> %@", trueDepPackageID, depPackage);
        
        if (depPackage != NULL) {
            if ([databaseManager packageIsInstalled:depPackage versionStrict:NO]) {
                ZBLog(@"[Zebra] Final OR dependency: %@", depPackage);
                return depPackage;
            } else {
                [results addObject:depPackage];
            }
        }
    }
    
    if ([results count]) {
        ZBLog(@"[Zebra] Final OR dependency (fallback): %@", results[0]);
        return results[0]; // The first one is probably fine
    }
    
    return NULL;
}

- (ZBPackage *)packageThatSatisfiesVersionComparison:(NSString *)line checkProvides:(BOOL)provides {
    NSUInteger openIndex = [line rangeOfString:@"("].location;
    NSUInteger closeIndex = [line rangeOfString:@")"].location;
    
    NSString *depPackageID = [[line substringToIndex:openIndex] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *versionPredicate = [[line substringWithRange:NSMakeRange(openIndex + 1, closeIndex - openIndex)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *separate = [versionPredicate componentsSeparatedByString:@" "];
    
    if ([separate count] > 1) {
        NSString *comparison = separate[0];
        NSString *version = [separate[1] substringToIndex:[separate[1] length] - 1];
        ZBLog(@"[Zebra] Trying to resolve version, %@ needs to be %@ than %@", depPackageID, comparison, version);
        return [databaseManager packageForID:depPackageID thatSatisfiesComparison:comparison ofVersion:version checkInstalled:YES checkProvides:provides];
    } else { // bad repo maintainer alert
        NSString *comparison;
        NSString *version;
        NSScanner *scanner = [NSScanner scannerWithString:versionPredicate];
        NSCharacterSet *versionChars = [NSCharacterSet characterSetWithCharactersInString:@":.+-~abcdefghijklmnopqrstuvwxyz0123456789"];
        [scanner scanUpToCharactersFromSet:versionChars intoString:&comparison];
        [scanner scanCharactersFromSet:versionChars intoString:&version];
        
        ZBLog(@"[Zebra] Trying to resolve version, %@ needs to be %@ than %@", depPackageID, comparison, version);
        return [databaseManager packageForID:depPackageID thatSatisfiesComparison:comparison ofVersion:version checkInstalled:YES checkProvides:provides];
    }
    
}

- (void)conflictionsWithPackage:(ZBPackage *)package state:(int)state {
    sqlite3 *database = [databaseManager database];
    if (state == 0) { // Installing package
        // First, check if package conflicts with any packages that are currently installed
        NSArray *conflictions = [package conflictsWith];
        
        for (NSString *line in conflictions) {
            ZBPackage *conf = [self packageThatResolvesDependency:line checkProvides:NO];
            if (conf != NULL && [databaseManager packageIsInstalled:conf versionStrict:YES]) {
                if ([[package provides] containsObject:conf.identifier] || [[package replaces] containsObject:conf.identifier]) {
                    // If this package can provide or replace this conflicting package, we can remove this conflicting package
                    // This also means, we have to install "package" first before we remove "conf"
                    ZBLog(@"[Zebra] Installing %@ triggers removing of %@, but we will let dpkg handle it", package, conf);
                    continue;
                } else {
                    // Just remove this package
                    ZBLog(@"[Zebra] Removing %@ due to being conflicted with %@", conf, package);
                    [queue addPackage:conf toQueue:ZBQueueTypeRemove];
                }
            }
        }
        
        // Then, check if any package that is installed conflicts with package
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE CONFLICTS LIKE \'%%%@%%\' AND REPOID < 1;", package.identifier];

        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *conf = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                if (![[conf conflictsWith] containsObject:package.identifier]) {
                    // Skip false positives
                    continue;
                }
                if ([[conf conflictsWith] containsObject:package.identifier]) {
                    // If this conflicting package (conf) conflicts with this not-installed package, we remove conf
                    ZBLog(@"[Zebra] Removing %@ because it conflicts with %@", conf, package);
                    [queue addPackage:conf toQueue:ZBQueueTypeRemove];
                    continue;
                } else if ([[conf provides] containsObject:package.identifier] || [[conf replaces] containsObject:package.identifier]) {
                    // If this conflicting package (conf) can replace this not-installed package, we don't have to install this package (package)
                    ZBLog(@"[Zebra] Skipping installation of %@ because %@ can substitute", package, conf);
                    [queue removePackage:package fromQueue:ZBQueueTypeInstall];
                    continue;
                }
                [queue markPackageAsFailed:package forConflicts:conf conflictionType:1];
                break;
            }
        } else {
            [databaseManager printDatabaseError];
        }
        sqlite3_finalize(statement);
    } else if (state == 1) { // Removing package
        // Check if any package that is installed depends on this package
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE DEPENDS LIKE \'%%%@%%\' AND REPOID < 1;", package.identifier];
        
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *dependingPackage = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                // Before we actually remove this package, it is possible that this package is to be removed due to its dependency being removed
                // If there is such other dependency that can provide, we should not remove this package
                BOOL shouldRemove = YES;
                for (NSString *line in [dependingPackage dependsOn]) {
                    ZBPackage *depPackage = [self packageThatResolvesDependency:line checkProvides:NO];
                    if (depPackage) {
                        ZBPackage *providingPackage = [databaseManager packageThatProvides:depPackage.identifier checkInstalled:YES];
                        if (providingPackage && shouldRemove) {
                            shouldRemove = NO;
                            ZBLog(@"[Zebra] Should we remove %@ because its dependency being removed? : %d", dependingPackage, shouldRemove);
                            break;
                        }
                    }
                }
                if (shouldRemove) {
                    if ([databaseManager packageHasUpdate:dependingPackage]) {
                        ZBLog(@"[Zebra] %@ has an update, we can just let APT handle it without removing by ourselves", dependingPackage);
                    } else {
                        ZBLog(@"[Zebra] Removing %@ as required by %@", dependingPackage, package);
                        [queue addPackage:dependingPackage toQueue:ZBQueueTypeRemove requiredBy:package];
                    }
                }
            }
        } else {
            [databaseManager printDatabaseError];
        }
        sqlite3_finalize(statement);
    }
}

- (void)dealloc {
    [databaseManager closeDatabase];
}

@end
