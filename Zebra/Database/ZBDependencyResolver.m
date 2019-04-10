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
    if ([databaseManager packageIsInstalled:package versionStrict:true inDatabase:database]) {
        NSLog(@"[Zebra] %@ (%@) is already installed, dependencies resolved.", [package name], [package identifier]);
        return;
    }
    
    NSArray *dependencies = [package dependsOn];
    
    for (NSString *line in dependencies) {
        ZBPackage *depPackage = [self packageThatResolvesDependency:line];
        if (depPackage != NULL) {
            if ([databaseManager packageIsInstalled:depPackage versionStrict:true inDatabase:database]) {
                NSLog(@"[Zebra] %@ is already installed, skipping", [package identifier]);
                continue;
            }
            else { //Dependency found, all gucci
                NSLog(@"Resolved: %@", depPackage);
                [queue addPackage:depPackage toQueue:ZBQueueTypeInstall];
            }
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
    
    if ([separate count] > 1) {
        NSString *comparison = separate[0];
        NSString *version = [separate[1] substringToIndex:[separate[1] length] - 1];
        
        NSLog(@"[Zebra] Trying to resolve version, %@ needs to be %@ than %@", depPackageID, comparison, version);
        return [databaseManager packageForID:depPackageID thatSatisfiesComparison:comparison ofVersion:version inDatabase:database];
    }
    else { //bad repo maintainer alert
        NSString *versionComparison = [components[1] substringToIndex:[components[1] length] - 1];
        NSString *comparison;
        NSString *version;
        
        NSScanner *scanner = [NSScanner scannerWithString:versionComparison];
        NSCharacterSet *versionChars = [NSCharacterSet characterSetWithCharactersInString:@":.+-~abcdefghijklmnopqrstuvwxyz0123456789"];
        
        [scanner scanUpToCharactersFromSet:versionChars intoString:&comparison];
        [scanner scanCharactersFromSet:versionChars intoString:&version];
        
        NSLog(@"[Zebra] Trying to resolve version, %@ needs to be %@ than %@", depPackageID, comparison, version);
        return [databaseManager packageForID:depPackageID thatSatisfiesComparison:comparison ofVersion:version inDatabase:database];
    }
    
}

@end
