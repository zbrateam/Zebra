//
//  ZBDependencyResolver.m
//  Zebra
//
//  Created by Wilson Styres on 3/26/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBDependencyResolver.h"

#import <Tabs/Packages/Helpers/ZBPackage.h>

#import <Database/ZBDatabaseManager.h>
#import <Queue/ZBQueue.h>

@interface ZBDependencyResolver () {
    NSArray *installedPackagesList;
    NSArray *virtualPackagesList;
    NSMutableArray *dependencies;
}
@end

@implementation ZBDependencyResolver

+ (id)sharedInstance {
    static ZBDependencyResolver *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBDependencyResolver new];
    });
    return instance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        databaseManager = [ZBDatabaseManager sharedInstance];
        queue = [ZBQueue sharedInstance];
    }
    
    return self;
}

#pragma mark - Immediate dependency resolution

- (BOOL)resolveDependenciesForPackage:(ZBPackage *)package {
    [self populateLists];
    
    //Resolve dependencies first
    for (NSString *dependency in [package dependsOn]) {
        if (![self resolveDependency:[dependency stringByReplacingOccurrencesOfString:@" " withString:@""]]) { //Remove all spaces from dependency and start resolution
            return false;
        }
    }
    
    //Then resolve conflicts
    
    return true;
}

- (BOOL)resolveDependency:(NSString *)dependency {
    if ([dependency containsString:@"|"]) { //There is an OR dependency here, process them in the order they appear
        NSArray *orDependencies = [dependency componentsSeparatedByString:@"|"];
        for (NSString *orDependency in orDependencies) {
            if ([self resolveDependency:orDependency]) {
                return true;
            }
        }
        
        return false;
    }
    else if ([dependency containsString:@"("] || [dependency containsString:@")"]) { //There is a version dependency here
        NSUInteger openIndex = [dependency rangeOfString:@"("].location;
        NSUInteger closeIndex = [dependency rangeOfString:@")"].location;
        
        NSString *packageIdentifier = [[dependency substringToIndex:openIndex] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSString *version = [[dependency substringWithRange:NSMakeRange(openIndex + 1, closeIndex - openIndex - 1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *comparison;
        
        NSScanner *scanner = [NSScanner scannerWithString:version];
        NSCharacterSet *versionChars = [NSCharacterSet characterSetWithCharactersInString:@":.+-~abcdefghijklmnopqrstuvwxyz0123456789"];
        [scanner scanUpToCharactersFromSet:versionChars intoString:&comparison];
        [scanner scanCharactersFromSet:versionChars intoString:&version];
        
        //We should now have a separate version and a comparison string
        
        ZBPackage *dependency = [databaseManager packageForID:packageIdentifier thatSatisfiesComparison:comparison ofVersion:version checkInstalled:false checkProvides:false];
        return dependency != NULL;
    }
    else { //We should just be left as a package ID at this point, lets search for it in the database
        return [databaseManager packageIDIsAvailable:dependency version:NULL];
    }
}

#pragma mark - Helper functions

- (void)populateLists { //Populates a list of packages that are installed and a list of virtual packages of which the installed packages provide.
    if (!dependencies) dependencies = [NSMutableArray new];
    
    NSDictionary *packageList = [databaseManager installedPackagesList];
    installedPackagesList = [packageList objectForKey:@"installed"];
    virtualPackagesList = [packageList objectForKey:@"virtual"];
}

@end
