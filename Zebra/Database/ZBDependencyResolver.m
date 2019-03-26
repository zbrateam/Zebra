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

@implementation ZBDependencyResolver

@synthesize databaseManager;
@synthesize database;

- (id)init {
    self = [super init];
    
    if (self) {
        databaseManager = [[ZBDatabaseManager alloc] init];
        
        sqlite3_open([[ZBAppDelegate databaseLocation] UTF8String], &database);
    }
    
    return self;
}

- (NSArray *)dependenciesForPackage:(ZBPackage *)package {
    if ([databaseManager packageIsInstalled:[package identifier] inDatabase:database]) {
        NSLog(@"%@ (%@) is already installed, dependencies resolved.", [package name], [package identifier]);
        return NULL;
    }
    
    NSArray *dependencies = [self getDependenciesForPackage:package alreadyQueued:@[package]];
    
    NSLog(@"Dependencies for package %@: %@", [package name], dependencies);
    
    return dependencies;
}

- (NSArray *)getDependenciesForPackage:(ZBPackage *)package alreadyQueued:(NSArray *)qd {
    NSMutableArray *queued = [qd mutableCopy];
//
//    NSString *query = [NSString stringWithFormat:@"SELECT DEPENDS FROM PACKAGES WHERE PACKAGE = \'%@\' AND REPOID != 0;", package];
//
//    NSArray *dependencies;
//    sqlite3_stmt *dependsStatement;
//    sqlite3_prepare_v2(database, [query UTF8String], -1, &dependsStatement, nil);
//    while (sqlite3_step(dependsStatement) == SQLITE_ROW) {
//        const char *dependsChar = (const char *)sqlite3_column_text(dependsStatement, 0);
//
//        if (dependsChar != 0) {
//            dependencies = [[NSString stringWithUTF8String:dependsChar] componentsSeparatedByString:@", "];
//        }
//    }
//    sqlite3_finalize(dependsStatement);
    
    NSArray *dependencies = [package dependsOn];
    
    for (NSString *line in dependencies) {
        NSArray *comps = [line componentsSeparatedByString:@" ("]; //Gets rid of version requirement (for now)
        comps = [comps[0] componentsSeparatedByString:@" |"]; //Gets rid of | operator (for now)
        NSString *depPackageID = comps[0];
        NSString *depPackgageVersion = NULL;
        ZBPackage *depPackage = [databaseManager packageForID:depPackageID version:depPackgageVersion inDatabase:database];
        
        if ([queued containsObject:[depPackage identifier]]) {
            NSLog(@"%@ is already queued, skipping", depPackageID);
            continue;
        }
        
        if ([databaseManager packageIsInstalled:[depPackage identifier] inDatabase:database]) {
            NSLog(@"%@ is already installed, skipping", [depPackage identifier]);
            continue;
        }
        else if ([databaseManager packageIsAvailable:[depPackage identifier] inDatabase:database]) {
            NSLog(@"%@ is available, adding it to queued packages", [depPackage identifier]);
            if (![queued containsObject:depPackage]) {
                [queued addObject:depPackage];
                
                NSArray *depsForDep = [self getDependenciesForPackage:depPackage alreadyQueued:queued];
                for (ZBPackage *dep in depsForDep) {
                    if (![queued containsObject:dep]) {
                        [queued addObject:dep];
                    }
                }
            }
            else {
                NSLog(@"%@ is already queued (2), skipping", [depPackage identifier]);
            }
            
            
        }
        else {
            NSLog(@"Cannot resolve dependencies for %@ because %@ cannot be found", [package identifier], [depPackage identifier]);
        }
        
    }
    
    return queued;
}

@end
