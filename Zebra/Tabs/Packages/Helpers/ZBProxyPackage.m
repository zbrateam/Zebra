//
//  ZBProxyPackage.m
//  Zebra
//
//  Created by Wilson Styres on 2/23/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBProxyPackage.h"
#import "ZBPackage.h"

#import "ZBDatabaseManager.h"
#import "ZBSource.h"
#import "ZBDevice.h"
#import "UIImageView+Zebra.h"

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
        const char *packageIDChars    = (const char *)sqlite3_column_text(statement, 0);
        const char *packageNameChars  = (const char *)sqlite3_column_text(statement, 1);
        const char *versionChars      = (const char *)sqlite3_column_text(statement, 2);
        const char *architectureChars = (const char *)sqlite3_column_text(statement, 3);
        int sourceID                  =               sqlite3_column_int(statement, 4);
        
        [self setIdentifier:[NSString stringWithUTF8String:packageIDChars]]; // This should never be NULL
        [self setName:packageNameChars != 0 ? ([NSString stringWithUTF8String:packageNameChars] ?: [NSString stringWithCString:packageNameChars encoding:NSASCIIStringEncoding]) : (self.identifier ?: @"Unknown")];
        [self setVersion:versionChars != 0 ? [NSString stringWithUTF8String:versionChars] : NULL];
        [self setArchitecture:architectureChars != 0 ? [NSString stringWithUTF8String:architectureChars] : NULL];
        [self setSourceID:sourceID];
    }
    
    return self;
}

- (BOOL)isArchitectureCompatible {
    return [_architecture isEqualToString:@"all"] || [[ZBDevice allDebianArchitectures] containsObject:_architecture];
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

- (void)setIconImageForImageView:(UIImageView *)imageView variant:(MIIconVariant)variant {
    UIImage *sectionImage = [ZBSource imageForSection:self.section];
    if (self.iconURL) {
        __weak UIImageView *weakImageView = imageView;
        [imageView setRetinaImageWithURL:self.iconURL placeholderImage:sectionImage completed:^(UIImage *image, __unused NSError *error, __unused SDImageCacheType cacheType, __unused NSURL *imageURL) {
            [weakImageView setIconImage:image variant:variant];
        }];
    }
    else {
        imageView.zb_imageURL = nil;
        [imageView setIconImage:sectionImage variant:variant];
    }
}

@end
