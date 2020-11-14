//
//  ZBBasePackage.m
//  Zebra
//
//  Created by Wilson Styres on 10/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBBasePackage.h"

#import <Managers/ZBPackageManager.h>
#import <Managers/ZBSourceManager.h>
#import <Model/ZBSource.h>
#import <ZBSettings.h>

@import UIKit.UIImageView;
@import SDWebImage;

@class ZBPackage;

@interface ZBBasePackage () {
    ZBPackage *forwardingPackage;
}
@end

@implementation ZBBasePackage

@synthesize isInstalled = _isInstalled;

- (id)initFromSQLiteStatement:(sqlite3_stmt *)statement {
    self = [super init];
    
    if (self) {
        const char *authorName = (const char *)sqlite3_column_text(statement, ZBPackageColumnAuthorName);
        if (authorName && authorName[0] != '\0') {
            self.authorName = [NSString stringWithUTF8String:authorName];
        }
        
        const char *description = (const char *)sqlite3_column_text(statement, ZBPackageColumnDescription);
        if (description && description[0] != '\0') {
            self.packageDescription = [NSString stringWithUTF8String:description];
        } else { // Packages cannot exist without a description (apparently)
            return NULL;
        }
        
        const char *iconURL = (const char *)sqlite3_column_text(statement, ZBPackageColumnIconURL);
        if (iconURL && iconURL[0] != '\0') {
            NSString *iconURLString = [NSString stringWithUTF8String:iconURL];
            _iconURL = [NSURL URLWithString:iconURLString];
        }
        
        const char *identifier = (const char *)sqlite3_column_text(statement, ZBPackageColumnIdentifier);
        if (identifier && identifier[0] != '\0') {
            self.identifier = [NSString stringWithUTF8String:identifier];
        } else { // Packages cannot exist without an identifier
            return NULL;
        }
        
        sqlite3_int64 lastSeen = sqlite3_column_int64(statement, ZBPackageColumnLastSeen);
        self.lastSeen = lastSeen ? [NSDate dateWithTimeIntervalSince1970:lastSeen] : [NSDate distantPast];
        
        const char *name = (const char *)sqlite3_column_text(statement, ZBPackageColumnName);
        if (name && name[0] != '\0') {
            self.name = [NSString stringWithUTF8String:name];
        } else { // If there isn't a name, set the name to the identifier
            self.name = self.identifier;
        }
        
        self.role = sqlite3_column_int(statement, ZBPackageColumnRole);
        
        const char *section = (const char *)sqlite3_column_text(statement, ZBPackageColumnSection);
        if (section && section[0] != '\0') {
            self.section = [NSString stringWithUTF8String:section];
        }
        
        const char *source = (const char *)sqlite3_column_text(statement, ZBPackageColumnSource);
        if (source && source) {
            self.source = [[ZBSourceManager sharedInstance] sourceWithUUID:[NSString stringWithUTF8String:source]];
        }
        
        const char *tag = (const char *)sqlite3_column_text(statement, ZBPackageColumnTag);
        if (tag && tag[0] != '\0') {
            NSString *rawTag = [NSString stringWithUTF8String:tag];
            self.tag = [rawTag componentsSeparatedByString:@","];
        }
        
        const char *uuid = (const char *)sqlite3_column_text(statement, ZBPackageColumnUUID);
        if (uuid && uuid[0] != '\0') {
            self.uuid = [NSString stringWithUTF8String:uuid];
        }
        
        const char *version = (const char *)sqlite3_column_text(statement, ZBPackageColumnVersion);
        if (version && version[0] != '\0') {
            self.version = [NSString stringWithUTF8String:version];
        } else { // Packages cannot exist without a version
            return NULL;
        }
    }
    
    return self;
}

- (BOOL)isInstalled {
    if (self.source && [self.source.uuid isEqualToString:@"_var_lib_dpkg_status"]) {
        _isInstalled = YES;
    }
    
    if (!_isInstalled) [[ZBPackageManager sharedInstance] isPackageInstalled:self];
    
    return _isInstalled;
}

- (BOOL)isPaid {
    return [self.tag containsObject:@"cydia::commercial"];
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

- (void)setIconImageForImageView:(UIImageView *)imageView {
    UIImage *sectionImage = [ZBSource imageForSection:self.section];
    if (self.iconURL) {
        [imageView sd_setImageWithURL:self.iconURL placeholderImage:sectionImage];
    }
    else {
        [imageView setImage:sectionImage];
    }
}

@end
