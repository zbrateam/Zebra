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
#import <ZBDevice.h>
#import <ZBSettings.h>

@import UIKit.UIImageView;
@import FirebaseCrashlytics;
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
        
        int downloadSize = sqlite3_column_int(statement, ZBPackageColumnDownloadSize);
        self.downloadSize = downloadSize;
        
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
        
        int installedSize = sqlite3_column_int(statement, ZBPackageColumnInstalledSize);
        self.installedSize = installedSize;
        
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
            NSMutableArray *tags = [rawTag componentsSeparatedByString:@","].mutableCopy;
            for (int i = 0; i < tags.count; i++) {
                tags[i] = [tags[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
            self.tag = tags;
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
    if (_isInstalled) return _isInstalled;
    
    if (self.source && [self.source.uuid isEqualToString:@"_var_lib_dpkg_status"]) {
        _isInstalled = YES;
    }
    
    if (!_isInstalled) _isInstalled = [[ZBPackageManager sharedInstance] isPackageInstalled:self];
    
    return _isInstalled;
}

- (BOOL)isPaid {
    return [self.tag containsObject:@"cydia::commercial"];
}

- (BOOL)isFavorited {
    return [[ZBSettings favoritePackages] containsObject:self.identifier];
}

- (NSDate *)installedDate {
    if ([ZBDevice needsSimulation]) {
        // Just to make sections in simulators less cluttered
        // https://stackoverflow.com/questions/1149256/round-nsdate-to-the-nearest-5-minutes/19123570
        NSTimeInterval seconds = round([[NSDate date] timeIntervalSinceReferenceDate] / 300.0) * 300.0;
        return [NSDate dateWithTimeIntervalSinceReferenceDate:seconds];
    }
    NSString *listPath = [NSString stringWithFormat:@"/var/lib/dpkg/info/%@.list", self.identifier];
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:listPath error:NULL];
    return attributes[NSFileModificationDate];
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

- (id)forwardingTargetForSelector:(SEL)aSelector {
    @synchronized (self) {
        if (forwardingPackage) return forwardingPackage;
            
        ZBPackage *package = [[ZBPackageManager sharedInstance] packageWithUniqueIdentifier:self.uuid];
        if (package) forwardingPackage = package;
        
        if (!forwardingPackage) {
            [[FIRCrashlytics crashlytics] logWithFormat:@"Unable to fetch %@ for %@ (%@) v%@ from %@ (%@)", self.uuid, self.name, self.identifier, self.version, self.source.label, self.source.uuid];
        }
            
        return forwardingPackage;
    }
}

@end
