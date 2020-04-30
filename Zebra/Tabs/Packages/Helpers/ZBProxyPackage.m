//
//  ZBProxyPackage.m
//  Zebra
//
//  Created by Wilson Styres on 2/23/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBProxyPackage.h"
#import "ZBPackage.h"

#import <Database/ZBDatabaseManager.h>
#import <Sources/Helpers/ZBSource.h>

@import SDWebImage;

@implementation ZBProxyPackage

@synthesize name;
@synthesize identifier;
@synthesize version;
@synthesize sourceID;

@synthesize author;
@synthesize iconURL;
@synthesize section;

@synthesize package;

- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement {
    self = [super init];
    
    if (self) {
        const char *packageIDChars   = (const char *)sqlite3_column_text(statement, 0);
        const char *packageNameChars = (const char *)sqlite3_column_text(statement, 1);
        const char *versionChars     = (const char *)sqlite3_column_text(statement, 2);
        int sourceID                 =               sqlite3_column_int(statement, 3);
        
        [self setIdentifier:[NSString stringWithUTF8String:packageIDChars]]; // This should never be NULL
        [self setName:packageNameChars != 0 ? ([NSString stringWithUTF8String:packageNameChars] ?: [NSString stringWithCString:packageNameChars encoding:NSASCIIStringEncoding]) : (self.identifier ?: @"Unknown")];
        [self setVersion:versionChars != 0 ? [NSString stringWithUTF8String:versionChars] : NULL];
        [self setSourceID:sourceID];
    }
    
    return self;
}

- (BOOL)isInstalled {
    if (sourceID <= 0)
        return YES;
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    return [databaseManager packageIDIsInstalled:self.identifier version:nil];
}

- (ZBPackage *)loadPackage {
    if (package) return package;
    
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    
    return [databaseManager topVersionForPackageID:[self identifier]];
}

- (BOOL)sameAs:(ZBProxyPackage *)package {
    return [self.identifier isEqualToString:package.identifier];
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
