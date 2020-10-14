//
//  ZBBasePackage.m
//  Zebra
//
//  Created by Wilson Styres on 10/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBBasePackage.h"
#import "ZBPackage.h"

#import <Database/ZBColumn.h>
#import <Managers/ZBDatabaseManager.h>

@interface ZBBasePackage () {
    ZBPackage *forwardingPackage;
}
@end

@implementation ZBBasePackage

- (id)initFromSQLiteStatement:(sqlite3_stmt *)statement {
    self = [super init];
    
    if (self) {
        const char *description = (const char *)sqlite3_column_text(statement, ZBPackageColumnDescription);
        if (description != NULL) {
            self.packageDescription = [NSString stringWithUTF8String:description];
        } else { // Packages cannot exist without a description (apparently)
            return NULL;
        }
        
        const char *identifier = (const char *)sqlite3_column_text(statement, ZBPackageColumnIdentifier);
        if (identifier != NULL) {
            self.identifier = [NSString stringWithUTF8String:identifier];
        } else { // Packages cannot exist without an identifier
            return NULL;
        }
        
        const char *name = (const char *)sqlite3_column_text(statement, ZBPackageColumnName);
        if (name != NULL) {
            self.name = [NSString stringWithUTF8String:name];
        } else { // If there isn't a name, set the name to the identifier
            self.name = self.identifier;
        }
        
        const char *version = (const char *)sqlite3_column_text(statement, ZBPackageColumnVersion);
        if (version != NULL) {
            self.version = [NSString stringWithUTF8String:version];
        } else { // Packages cannot exist without a version
            return NULL;
        }
        
        const char *section = (const char *)sqlite3_column_text(statement, ZBPackageColumnSection);
        if (section != NULL) {
            self.section = [NSString stringWithUTF8String:section];
        }
        
        const char *authorName = (const char *)sqlite3_column_text(statement, ZBPackageColumnAuthorName);
        if (authorName != NULL) {
            self.authorName = [NSString stringWithUTF8String:authorName];
        }
        
        sqlite3_int64 lastSeen = sqlite3_column_int64(statement, ZBPackageColumnLastSeen);
        self.lastSeen = lastSeen ? [NSDate dateWithTimeIntervalSince1970:lastSeen] : [NSDate date];
        
        const char *uuid = (const char *)sqlite3_column_text(statement, ZBPackageColumnUUID);
        if (uuid != NULL) {
            self.uuid = [NSString stringWithUTF8String:uuid];
        }
    }
    
    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (forwardingPackage) return forwardingPackage;
    
    ZBPackage *package = [[ZBDatabaseManager sharedInstance] packageWithUniqueIdentifier:self.uuid];
    
    if (package) {
        forwardingPackage = package;
    }
    
    return forwardingPackage;
}

@end
