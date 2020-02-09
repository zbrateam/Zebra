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

#pragma mark - Version Comparison separation

+ (NSArray *)separateVersionComparison:(NSString *)dependency {
    if ([dependency isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dep = (NSDictionary *)dependency;
        NSString *version = [dep objectForKey:@"version"];
        NSString *identifier = [dep objectForKey:@"identifier"];
        
        return @[identifier, @"=", version];
    }
    
    NSUInteger openIndex = [dependency rangeOfString:@"("].location;
    NSUInteger closeIndex = [dependency rangeOfString:@")"].location;
    
    if (openIndex == NSNotFound || closeIndex == NSNotFound) {
        return @[dependency, @"<=>", @"0:0"];
    }
    
    NSString *packageIdentifier = [[dependency substringToIndex:openIndex] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    packageIdentifier = [packageIdentifier lowercaseString];
    
    NSString *version = [[dependency substringWithRange:NSMakeRange(openIndex + 1, closeIndex - openIndex - 1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *comparison;
    
    NSScanner *scanner = [NSScanner scannerWithString:version];
    NSCharacterSet *versionChars = [NSCharacterSet characterSetWithCharactersInString:@":.+-~abcdefghijklmnopqrstuvwxyz0123456789"];
    [scanner scanUpToCharactersFromSet:versionChars intoString:&comparison];
    [scanner scanCharactersFromSet:versionChars intoString:&version];
    
    return @[packageIdentifier, comparison, version];
}

+ (BOOL)doesPackage:(ZBPackage *)package satisfyComparison:(nonnull NSString *)comparison ofVersion:(nonnull NSString *)version {
    return [self doesVersion:[package version] satisfyComparison:comparison ofVersion:version];
}

+ (BOOL)doesVersion:(NSString *)candidate satisfyComparison:(NSString *)comparison ofVersion:(NSString *)version {
    NSArray *choices = @[@"<<", @"<=", @"=", @">=", @">>"];
    comparison = [comparison stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (candidate == NULL)
        return NO;
    
    if (version == NULL || comparison == NULL || ([comparison isEqualToString:@"<=>"] && [version isEqualToString:@"0:0"]))
        return YES;

    int nx = (int)[choices indexOfObject:comparison];
    NSComparisonResult result = [self compareVersion:candidate toVersion:version];
    switch (nx) {
        case 0:
            return result == NSOrderedAscending;
        case 1:
            return result == NSOrderedAscending || result == NSOrderedSame;
        case 2:
            return result == NSOrderedSame;
        case 3:
            return result == NSOrderedDescending || result == NSOrderedSame;
        case 4:
            return result == NSOrderedDescending;
        default:
            return NO;
    }
}

+ (NSComparisonResult)compareVersion:(NSString *)firstVersion toVersion:(NSString *)secondVersion {
    int result = compare([firstVersion UTF8String], [secondVersion UTF8String]);
    if (result < 0)
        return NSOrderedAscending;
    if (result > 0)
        return NSOrderedDescending;
    return NSOrderedSame;
}

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
    NSArray *packagesThatConflictWith = [databaseManager packagesThatConflictWith:package];
    if ([packagesThatConflictWith count] > 0) {
        for (ZBPackage *conflict in packagesThatConflictWith) {
            if (![[package conflictsWith] containsObject:[conflict identifier]]) {
                //We cannot install this package as there are some already installed packages that conflict here
                [package addIssue:[NSString stringWithFormat:@"\"%@\" conflicts with %@", [conflict name], [package name]]];
            }
        }
    }
    
    if ([package hasIssues]) {
        return NO;
    }
    
    for (NSString *conflictLine in [package conflictsWith]) {
        if ([[package replaces] containsObject:conflictLine] || [[package provides] containsObject:conflictLine]) continue;
        NSArray *conflict = [ZBDependencyResolver separateVersionComparison:conflictLine];
        BOOL needsVersionComparison = ![conflict[1] isEqualToString:@"<=>"] && ![conflict[2] isEqualToString:@"0:0"];
        
        for (NSDictionary *virtualPackage in virtualPackagesList) {
            NSString *version = [virtualPackage objectForKey:@"version"];
            NSString *identifier = [virtualPackage objectForKey:@"identifier"];
            
            //If there is a version comparison and the virtual package has a version, check against the version and add a conflict if true
            if ([identifier isEqualToString:conflict[0]] && (needsVersionComparison && ![version isEqualToString:@"0:0"]) && ([ZBDependencyResolver doesVersion:version satisfyComparison:conflict[1] ofVersion:conflict[2]])) {
                [package addIssue:[NSString stringWithFormat:@"\"%@\" conflicts with %@", conflict[0], [package name]]];
                break;
            }
            //Otherwise, check if the identifier is equal and there is NO version comparison and NO version provided
            else if ([identifier isEqualToString:conflict[0]] && (!needsVersionComparison || version == NULL)) {
                [package addIssue:[NSString stringWithFormat:@"\"%@\" conflicts with %@", conflict[0], [package name]]];
                break;
            }
        }
    }
    
    if ([package hasIssues]) {
        return NO;
    }
    
    //Next, check if this package conflicts with any installed packages
    [self resolveConflicts:[package conflictsWith] forPackage:package];
    return YES;
}

- (BOOL)isDependencyResolved:(NSString *)dependency forPackage:(ZBPackage *)package {
    if ([dependency containsString:@"|"]) { //There is an OR dependency here, process them in the order they appear
        NSArray *orDependencies = [dependency componentsSeparatedByString:@"|"];
        for (NSString *orDependency in orDependencies) {
            if ([self isDependencyResolved:orDependency forPackage:package]) {
                return YES;
            }
        }
        
        return NO;
    }
    else if ([dependency containsString:@"("] || [dependency containsString:@")"]) { //There is a version dependency here
        NSArray *components = [ZBDependencyResolver separateVersionComparison:dependency];
        if ([[queue queuedPackagesList] containsObject:components[0]]) {
            ZBPackage *queuedDependency = [self packageInDependencyQueue:components[0]];
            if (queuedDependency != NULL) {
                [self enqueueDependency:queuedDependency forPackage:package ignoreFurtherDependencies:YES];
            }
            return YES;
        }
        
        //We should now have a separate version and a comparison string
        return [self isPackageInstalled:components[0] thatSatisfiesComparison:components[1] ofVersion:components[2]];
    }
    else { //We should just be left as a package ID at this point, lets search for it in the database
        if ([[queue queuedPackagesList] containsObject:dependency]) {
            ZBPackage *queuedDependency = [self packageInDependencyQueue:dependency];
            if (queuedDependency != NULL) {
                [self enqueueDependency:queuedDependency forPackage:package ignoreFurtherDependencies:YES];
            }
            return YES;
        }
        
        return [self isPackageInstalled:dependency];
    }
}

- (BOOL)resolveDependencies:(NSArray *)dependencies forPackage:(ZBPackage *)package {
    if (dependencies == NULL || [dependencies count] == 0) return YES;
    
    //At this point, we are left with only unresolved dependencies
    for (NSString *dependency in dependencies) {
        if (![self resolveDependency:dependency forPackage:package]) {
            ZBLog(@"Adding unresolved dependency for %@: %@", package, dependency);
            [package addIssue:dependency];
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)resolveDependency:(NSString *)dependency forPackage:(ZBPackage *)package {
    if ([dependency containsString:@"|"]) { //There is an OR dependency here, process them in the order they appear
        NSArray *orDependencies = [dependency componentsSeparatedByString:@"|"];
        for (NSString *orDependency in orDependencies) {
            if ([self resolveDependency:orDependency forPackage:package]) {
                return YES;
            }
        }
    }
    else if ([dependency containsString:@"("] || [dependency containsString:@")"]) { //There is a version dependency here
        NSArray *components = [ZBDependencyResolver separateVersionComparison:dependency];
        //We should now have a separate version and a comparison string
        
        ZBPackage *dependencyPackage = [databaseManager packageForIdentifier:components[0] thatSatisfiesComparison:components[1] ofVersion:components[2]];
        if (dependencyPackage) return [self enqueueDependency:dependencyPackage forPackage:package ignoreFurtherDependencies:NO];
    }
    else { //We should just be left as a package ID at this point, lets search for it in the database
        ZBPackage *dependencyPackage = [databaseManager packageForIdentifier:dependency thatSatisfiesComparison:NULL ofVersion:NULL];
        if (dependencyPackage) return [self enqueueDependency:dependencyPackage forPackage:package ignoreFurtherDependencies:NO];
    }
    
    return NO;
}

- (void)resolveConflicts:(NSArray *)conflicts forPackage:(ZBPackage *)package {
    for (NSString *conflict in conflicts) {
        [self resolveConflict:conflict forPackage:package];
    }
}

- (void)resolveConflict:(NSString *)conflict forPackage:(ZBPackage *)package {
    if ([conflict containsString:@"("] || [conflict containsString:@")"]) { //This package conflicts with a specific version
        NSArray *components = [ZBDependencyResolver separateVersionComparison:conflict];
        //We should now have a separate version and a comparison string
        
        ZBPackage *conflictingPackage = [databaseManager installedPackageForIdentifier:components[0] thatSatisfiesComparison:components[1] ofVersion:components[2] includeVirtualPackages:YES];
        if (conflictingPackage && ![[conflictingPackage identifier] isEqual:[package identifier]]) [self enqueueConflict:conflictingPackage forPackage:package];
    }
    else { //We should just be left as a package ID at this point, lets search for it in the database
        ZBPackage *conflictingPackage = [databaseManager installedPackageForIdentifier:conflict thatSatisfiesComparison:NULL ofVersion:NULL includeVirtualPackages:YES];
        
        if (conflictingPackage && ![[conflictingPackage identifier] isEqualToString:[package identifier]]) [self enqueueConflict:conflictingPackage forPackage:package];
    }
}

#pragma mark - Helper functions

- (BOOL)isPackage:(ZBPackage *)package providedBy:(ZBPackage *)provider {
    for (NSString *providedPackage in [provider provides]) {
        if ([providedPackage containsString:@"("] || [providedPackage containsString:@")"]) {
            NSArray *components = [ZBDependencyResolver separateVersionComparison:providedPackage];
            //We should now have a separate version and a comparison string
            
            if ([[package identifier] isEqualToString:components[0]]) {
                return [ZBDependencyResolver doesPackage:package satisfyComparison:components[1] ofVersion:components[2]];
            }
        }
        else {
            if ([[package identifier] isEqualToString:providedPackage]) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (void)populateLists { //Populates a list of packages that are installed and a list of virtual packages of which the installed packages provide.
    NSDictionary *packageList = [databaseManager installedPackagesList];
    
    installedPackagesList = [[packageList objectForKey:@"installed"] arrayByAddingObjectsFromArray:[queue installedPackagesListExcluding:self->package]];
    virtualPackagesList = [[packageList objectForKey:@"virtual"] arrayByAddingObjectsFromArray:[queue virtualPackagesListExcluding:self->package]];
}

- (BOOL)isPackageInstalled:(NSString *)packageIdentifier {
    return [self isPackageInstalled:packageIdentifier thatSatisfiesComparison:NULL ofVersion:NULL];
}

- (BOOL)isPackageInstalled:(NSString *)packageIdentifier thatSatisfiesComparison:(nullable NSString *)comparison ofVersion:(nullable NSString *)version { //Returns true if package is installed or is provided.
    for (NSDictionary *dict in installedPackagesList) {
        if ([[dict objectForKey:@"identifier"] isEqual:packageIdentifier]) {
            if (version != NULL && comparison != NULL) {
                return [ZBDependencyResolver doesVersion:[dict objectForKey:@"version"] satisfyComparison:comparison ofVersion:version];
            }
            
            return YES;
        }
    }
    
    return [self isPackageProvided:packageIdentifier thatSatisfiesComparison:comparison ofVersion:version];
}

- (BOOL)isPackageProvided:(NSString *)packageIdentifier thatSatisfiesComparison:(NSString *_Nullable)comparison ofVersion:(NSString *_Nullable)version {
    for (NSDictionary *providedPackage in virtualPackagesList) {
        NSString *virtualPackageIdentifier = [providedPackage objectForKey:@"identifier"];
        NSString *virtualPackageVersion    = [providedPackage objectForKey:@"version"];
        if ([packageIdentifier isEqualToString:virtualPackageIdentifier]) {
            if (comparison && version) { //If there is a version comparison, we can't return true for packages with no version so we MUST check if the package has a version and continue on otherwise
                BOOL needsVersionComparison = ![virtualPackageVersion isEqualToString:@"0:0"];
                if (needsVersionComparison && [ZBDependencyResolver doesVersion:virtualPackageVersion satisfyComparison:comparison ofVersion:version]) {
                    return YES; //If the virtual package provides a version that satisfies the comparison, we return true, otherwise we continue
                }
            }
            else {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)enqueueDependency:(ZBPackage *)dependency forPackage:(ZBPackage *)package ignoreFurtherDependencies:(BOOL)ignore {
    NSLog(@"[Zebra] Adding %@ as a dependency for %@", dependency, package);
    [package addDependency:dependency];
    [dependency addDependencyOf:package];
    [queue addDependency:dependency];
    
    return ignore ? YES : [self calculateDependenciesForPackage:dependency];
}

- (void)enqueueConflict:(ZBPackage *)conflict forPackage:(ZBPackage *)package {
    NSLog(@"[Zebra] Adding %@ as a conflict for %@", conflict, package);
    [package addDependency:conflict];
    [conflict addDependencyOf:package];
    [conflict setRemovedBy:package];
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

@end
