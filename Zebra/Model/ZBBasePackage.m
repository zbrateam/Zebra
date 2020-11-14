//
//  ZBBasePackage.m
//  Zebra
//
//  Created by Wilson Styres on 10/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBBasePackage.h"

#import <Managers/ZBPackageManager.h>
#import <ZBSettings.h>

@class ZBPackage;

@interface ZBBasePackage () {
    ZBPackage *forwardingPackage;
}
@end

@implementation ZBBasePackage

- (id)initFromSQLiteStatement:(sqlite3_stmt *)statement {
    self = [super init];
    
    if (self) {
        const char *authorName = (const char *)sqlite3_column_text(statement, ZBPackageColumnAuthorName);
        if (authorName[0] != '\0') {
            self.authorName = [NSString stringWithUTF8String:authorName];
        }
        
        const char *identifier = (const char *)sqlite3_column_text(statement, ZBPackageColumnIdentifier);
        if (identifier[0] != '\0') {
            self.identifier = [NSString stringWithUTF8String:identifier];
        } else { // Packages cannot exist without an identifier
            return NULL;
        }
        
        sqlite3_int64 lastSeen = sqlite3_column_int64(statement, ZBPackageColumnLastSeen);
        self.lastSeen = lastSeen ? [NSDate dateWithTimeIntervalSince1970:lastSeen] : [NSDate distantPast];
        
        const char *name = (const char *)sqlite3_column_text(statement, ZBPackageColumnName);
        if (name[0] != '\0') {
            self.name = [NSString stringWithUTF8String:name];
        } else { // If there isn't a name, set the name to the identifier
            self.name = self.identifier;
        }
        
        const char *description = (const char *)sqlite3_column_text(statement, ZBPackageColumnDescription);
        if (description[0] != '\0') {
            self.packageDescription = [NSString stringWithUTF8String:description];
        } else { // Packages cannot exist without a description (apparently)
            return NULL;
        }
        
        self.role = sqlite3_column_int(statement, ZBPackageColumnRole);
        
        const char *section = (const char *)sqlite3_column_text(statement, ZBPackageColumnSection);
        if (section[0] != '\0') {
            self.section = [NSString stringWithUTF8String:section];
        }
        
        const char *uuid = (const char *)sqlite3_column_text(statement, ZBPackageColumnUUID);
        if (uuid[0] != '\0') {
            self.uuid = [NSString stringWithUTF8String:uuid];
        }
        
        const char *version = (const char *)sqlite3_column_text(statement, ZBPackageColumnVersion);
        if (version[0] != '\0') {
            self.version = [NSString stringWithUTF8String:version];
        } else { // Packages cannot exist without a version
            return NULL;
        }
    }
    
    return self;
}

- (BOOL)isOnWishlist {
    return [[ZBSettings wishlist] containsObject:self.identifier];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (forwardingPackage) return forwardingPackage;
    
    ZBPackage *package = [[ZBPackageManager sharedInstance] packageWithUniqueIdentifier:self.uuid];
    if (package) forwardingPackage = package;
    
    return forwardingPackage;
}

@end
