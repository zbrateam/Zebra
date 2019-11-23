//
//  ZBDependencyResolver.m
//  Zebra
//
//  Created by Wilson Styres on 3/26/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBDependencyResolver.h"

#import <ZBLog.h>
#import <Tabs/Packages/Helpers/ZBPackage.h>

#import <Database/ZBDatabaseManager.h>
#import <Parsel/vercmp.h>
#import <Queue/ZBQueue.h>

@interface ZBDependencyResolver () {
    NSArray *installedPackagesList; //Packages that are installed on the device
    NSArray *virtualPackagesList;   //Packages that are provided by installed packages 
}
@end

@implementation ZBDependencyResolver

- (id)initWithPackage:(ZBPackage *)package {
    self = [super init];
    
    if (self) {
        databaseManager = [ZBDatabaseManager sharedInstance];
        queue = [ZBQueue sharedQueue];
        self->package = package;
        [self populateLists]; //This might cause some issues with efficiency when adding several packages.
    }
    
    return self;
}

#pragma mark - Immediate dependency resolution

- (BOOL)immediateResolution {
    return [self calculateDependenciesForPackage:self->package] && [self calculateConflictsForPackage:self->package];
}

- (BOOL)calculateDependenciesForPackage:(ZBPackage *)package {
    //On the first pass, remove any dependencies that are already satisfied
    NSMutableArray *unresolvedDependencies = [NSMutableArray new];
    for (NSString *dependency in [package dependsOn]) {
        NSString *unresolvedDependency = [dependency stringByReplacingOccurrencesOfString:@" " withString:@""];
        if (![self isDependencyResolved:unresolvedDependency forPackage:package]) {
            ZBLog(@"Adding unresolved dependency for %@: %@", package, unresolvedDependency);
            [unresolvedDependencies addObject:unresolvedDependency];
        }
    }
    
    return [self resolveDependencies:unresolvedDependencies forPackage:package];
}

- (BOOL)calculateConflictsForPackage:(ZBPackage *)package {
    //First lets check to see if any installed packages conflict with this package
    NSArray *packagesThatConflictWith = [[databaseManager packagesThatConflictWith:package] mutableCopy];
    if ([packagesThatConflictWith count] > 0) {
        //We cannot install this package as there are some already installed packages that conflict here
        for (ZBPackage *conflict in packagesThatConflictWith) {
            [package addIssue:[NSString stringWithFormat:@"\"%@\" conflicts with %@", [conflict name], [package name]]];
        }
        return false;
    }
    
    //Next, check if this package conflicts with any installed packages
    [self resolveConflicts:[package conflictsWith] forPackage:package];
    return true;
}

- (BOOL)isDependencyResolved:(NSString *)dependency forPackage:(ZBPackage *)package {
    if ([dependency containsString:@"|"]) { //There is an OR dependency here, process them in the order they appear
        NSArray *orDependencies = [dependency componentsSeparatedByString:@"|"];
        for (NSString *orDependency in orDependencies) {
            if ([self isDependencyResolved:orDependency forPackage:package]) {
                return true;
            }
        }
        
        return false;
    }
    else if ([dependency containsString:@"("] || [dependency containsString:@")"]) { //There is a version dependency here
        NSArray *components = [self separateVersionComparison:dependency];
        if ([[self queuedPackagesList] containsObject:components[0]]) {
            ZBPackage *queuedDependency = [self packageInDependencyQueue:components[0]];
            if (queuedDependency != NULL) {
                [self enqueueDependency:queuedDependency forPackage:package ignoreFurtherDependencies:true];
            }
            return true;
        }
        
        //We should now have a separate version and a comparison string
        return [self isPackageInstalled:components[0] thatSatisfiesComparison:components[1] ofVersion:components[2]];
    }
    else { //We should just be left as a package ID at this point, lets search for it in the database
        if ([[self queuedPackagesList] containsObject:dependency]) {
            ZBPackage *queuedDependency = [self packageInDependencyQueue:dependency];
            if (queuedDependency != NULL) {
                [self enqueueDependency:queuedDependency forPackage:package ignoreFurtherDependencies:true];
            }
            return true;
        }
        
        return [self isPackageInstalled:dependency];
    }
}

- (BOOL)resolveDependencies:(NSArray *)dependencies forPackage:(ZBPackage *)package {
    if ([dependencies count] == 0 || dependencies == NULL) return true;
    
    //At this point, we are left with only unresolved dependencies
    for (NSString *dependency in dependencies) {
        if (![self resolveDependency:dependency forPackage:package]) {
            ZBLog(@"Adding unresolved dependency for %@: %@", package, dependency);
            [package addIssue:dependency];
            return false;
        }
    }
    
    return true;
}

- (BOOL)resolveDependency:(NSString *)dependency forPackage:(ZBPackage *)package {
    if ([dependency containsString:@"|"]) { //There is an OR dependency here, process them in the order they appear
        NSArray *orDependencies = [dependency componentsSeparatedByString:@"|"];
        for (NSString *orDependency in orDependencies) {
            if ([self resolveDependency:orDependency forPackage:package]) {
                return true;
            }
        }
        
        return false;
    }
    else if ([dependency containsString:@"("] || [dependency containsString:@")"]) { //There is a version dependency here
        NSArray *components = [self separateVersionComparison:dependency];
        //We should now have a separate version and a comparison string
        
        ZBPackage *dependencyPackage = [databaseManager packageForIdentifier:components[0] thatSatisfiesComparison:components[1] ofVersion:components[2]];
        if (dependencyPackage) return [self enqueueDependency:dependencyPackage forPackage:package ignoreFurtherDependencies:false];
        
        return false;
    }
    else { //We should just be left as a package ID at this point, lets search for it in the database
        ZBPackage *dependencyPackage = [databaseManager packageForIdentifier:dependency thatSatisfiesComparison:NULL ofVersion:NULL];
        if (dependencyPackage) return [self enqueueDependency:dependencyPackage forPackage:package ignoreFurtherDependencies:false];
        
        return false;
    }
}

- (void)resolveConflicts:(NSArray *)conflicts forPackage:(ZBPackage *)package {
    for (NSString *conflict in conflicts) {
        [self resolveConflict:conflict forPackage:package];
    }
}

- (void)resolveConflict:(NSString *)conflict forPackage:(ZBPackage *)package {
    if ([conflict containsString:@"("] || [conflict containsString:@")"]) { //This package conflicts with a specific version
        NSArray *components = [self separateVersionComparison:conflict];
        //We should now have a separate version and a comparison string
        
        ZBPackage *conflictingPackage = [databaseManager installedPackageForIdentifier:components[0] thatSatisfiesComparison:components[1] ofVersion:components[2]];
        if (conflictingPackage && ![[conflictingPackage identifier] isEqual:[package identifier]]) [self enqueueConflict:conflictingPackage forPackage:package];
    }
    else { //We should just be left as a package ID at this point, lets search for it in the database
        ZBPackage *conflictingPackage = [databaseManager installedPackageForIdentifier:conflict thatSatisfiesComparison:NULL ofVersion:NULL];
        if (conflictingPackage && ![[conflictingPackage identifier] isEqual:[package identifier]]) [self enqueueConflict:conflictingPackage forPackage:package];
    }
}

#pragma mark - Helper functions

- (BOOL)isPackage:(ZBPackage *)package providedBy:(ZBPackage *)provider {
    for (NSString *providedPackage in [provider provides]) {
        if ([providedPackage containsString:@"("] || [providedPackage containsString:@")"]) {
            NSArray *components = [self separateVersionComparison:providedPackage];
            //We should now have a separate version and a comparison string
            
            if ([[package identifier] isEqualToString:components[0]]) {
                return [databaseManager doesPackage:package satisfyComparison:components[1] ofVersion:components[2]];
            }
        }
        else {
            if ([[package identifier] isEqualToString:providedPackage]) {
                return true;
            }
        }
    }
    
    return false;
}

- (void)populateLists { //Populates a list of packages that are installed and a list of virtual packages of which the installed packages provide.
    NSDictionary *packageList = [databaseManager installedPackagesList];
    installedPackagesList = [packageList objectForKey:@"installed"];
    virtualPackagesList = [packageList objectForKey:@"virtual"];
}

- (BOOL)isPackageInstalled:(NSString *)packageIdentifier {
    return [self isPackageInstalled:packageIdentifier thatSatisfiesComparison:NULL ofVersion:NULL];
}

- (BOOL)isPackageInstalled:(NSString *)packageIdentifier thatSatisfiesComparison:(nullable NSString *)comparison ofVersion:(nullable NSString *)version { //Returns true if package is installed or is provided.
    for (NSDictionary *dict in installedPackagesList) {
        if ([[dict objectForKey:@"identifier"] isEqual:packageIdentifier]) {
            if (version != NULL && comparison != NULL) {
                return [self doesVersion:[dict objectForKey:@"version"] satisfyComparison:comparison ofVersion:version];
            }
            
            return true;
        }
    }
    
    return [virtualPackagesList containsObject:packageIdentifier];
}

- (BOOL)doesVersion:(NSString *)candidate satisfyComparison:(NSString *)comparison ofVersion:(NSString *)version {
    NSArray *choices = @[@"<<", @"<=", @"=", @">=", @">>"];
    comparison = [comparison stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (version == NULL || comparison == NULL) return true;

    int nx = (int)[choices indexOfObject:comparison];
    switch (nx) {
        case 0:
            return [self compareVersion:candidate toVersion:version] == NSOrderedAscending;
        case 1:
            return [self compareVersion:candidate toVersion:version] == NSOrderedAscending || [self compareVersion:candidate toVersion:version] == NSOrderedSame;
        case 2:
            return [self compareVersion:candidate toVersion:version] == NSOrderedSame;
        case 3:
            return [self compareVersion:candidate toVersion:version] == NSOrderedDescending || [self compareVersion:candidate toVersion:version] == NSOrderedSame;
        case 4:
            return [self compareVersion:candidate toVersion:version] == NSOrderedDescending;
        default:
            return NO;
    }
}

- (NSComparisonResult)compareVersion:(NSString *)firstVersion toVersion:(NSString *)secondVersion {
    int result = compare([firstVersion UTF8String], [secondVersion UTF8String]);
    if (result < 0)
        return NSOrderedAscending;
    if (result > 0)
        return NSOrderedDescending;
    return NSOrderedSame;
}

- (NSArray *)separateVersionComparison:(NSString *)dependency {
    NSUInteger openIndex = [dependency rangeOfString:@"("].location;
    NSUInteger closeIndex = [dependency rangeOfString:@")"].location;
    
    NSString *packageIdentifier = [[dependency substringToIndex:openIndex] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *version = [[dependency substringWithRange:NSMakeRange(openIndex + 1, closeIndex - openIndex - 1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *comparison;
    
    NSScanner *scanner = [NSScanner scannerWithString:version];
    NSCharacterSet *versionChars = [NSCharacterSet characterSetWithCharactersInString:@":.+-~abcdefghijklmnopqrstuvwxyz0123456789"];
    [scanner scanUpToCharactersFromSet:versionChars intoString:&comparison];
    [scanner scanCharactersFromSet:versionChars intoString:&version];
    
    return @[packageIdentifier, comparison, version];
}

- (BOOL)enqueueDependency:(ZBPackage *)dependency forPackage:(ZBPackage *)package ignoreFurtherDependencies:(BOOL)ignore {
    NSLog(@"[Zebra] Adding %@ as a dependency for %@", dependency, package);
    [package addDependency:dependency];
    [dependency addDependencyOf:package];
    [queue addDependency:dependency];
    
    if (ignore) {
        return true;
    }
    return [self calculateDependenciesForPackage:dependency];
}

- (void)enqueueConflict:(ZBPackage *)conflict forPackage:(ZBPackage *)package {
    NSLog(@"[Zebra] Adding %@ as a conflict for %@", conflict, package);
    [package addDependency:conflict];
    [conflict addDependencyOf:package];
    [queue addConflict:conflict removeDependencies:![self isPackage:conflict providedBy:package]];
}

- (ZBPackage *)packageInDependencyQueue:(NSString *)packageID {
    for (ZBPackage *package in [queue dependencyQueue]) {
        if ([[package identifier] isEqual:packageID]) {
            return package;
        }
    }
    return NULL;
}

- (NSMutableArray *)queuedPackagesList {
    return [queue queuedPackagesList];
}

@end
