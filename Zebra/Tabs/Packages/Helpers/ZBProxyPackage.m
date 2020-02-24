//
//  ZBProxyPackage.m
//  Zebra
//
//  Created by Wilson Styres on 2/23/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBProxyPackage.h"

#import <Database/ZBDatabaseManager.h>

@implementation ZBProxyPackage

@synthesize name;
@synthesize identifier;
@synthesize version;
@synthesize repoID;

@synthesize author;
@synthesize iconURL;
@synthesize section;

@synthesize package;

- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement {
    self = [super init];
    
    if (self) {
        
    }
    
    return self;
}

- (id)forwardingTargetForSelector:(SEL)selector {
    if (package) return package;
    
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    package = [databaseManager packageFromProxy:self];
    
    return package;
}

@end
