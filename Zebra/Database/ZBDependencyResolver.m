//
//  ZBDependencyResolver.m
//  Zebra
//
//  Created by Wilson Styres on 3/26/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBDependencyResolver.h"

#import <Database/ZBDatabaseManager.h>
#import <Queue/ZBQueue.h>

@interface ZBDependencyResolver () {
    NSArray *installedArray;
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

- (void)resolveDependenciesForPackage:(ZBPackage *)package {
    [self createInstalledArray];
}

#pragma mark - Helper functions

- (void)createInstalledArray {
    if (!installedArray) {
        installedArray = [databaseManager installedPackagesList];
    }
}

@end
