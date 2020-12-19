//
//  ZBBasePackage.h
//  Zebra
//
//  Created by Wilson Styres on 10/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SQLite3;

@class UIImageView;
@class ZBSource;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZBPackageColumn) {
    // Base Package Columns
    ZBPackageColumnAuthorName,
    ZBPackageColumnDescription,
    ZBPackageColumnDownloadSize,
    ZBPackageColumnIconURL,
    ZBPackageColumnIdentifier,
    ZBPackageColumnInstalledSize,
    ZBPackageColumnLastSeen,
    ZBPackageColumnName,
    ZBPackageColumnRole,
    ZBPackageColumnSection,
    ZBPackageColumnSource,
    ZBPackageColumnTag,
    ZBPackageColumnUUID,
    ZBPackageColumnVersion,
    
    // Package Columns
    ZBPackageColumnAuthorEmail,
    ZBPackageColumnConflicts,
    ZBPackageColumnDepends,
    ZBPackageColumnDepictionURL,
    ZBPackageColumnEssential,
    ZBPackageColumnFilename,
    ZBPackageColumnHeader,
    ZBPackageColumnHomepageURL,
    ZBPackageColumnMaintainerEmail,
    ZBPackageColumnMaintainerName,
    ZBPackageColumnPriority,
    ZBPackageColumnProvides,
    ZBPackageColumnReplaces,
    ZBPackageColumnSHA256,
    ZBPackageColumnStatus,
    ZBPackageColumnCount,
};

typedef char *_Nonnull *_Nonnull ZBControlSource;

@interface ZBBasePackage : NSObject
@property (nonatomic) NSString *authorName;
@property (nonatomic) NSUInteger downloadSize;
@property (nonatomic) NSURL *_Nullable iconURL;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSUInteger installedSize;
@property (nonatomic) NSDate   *lastSeen;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *packageDescription;
@property (nonatomic) int16_t role;
@property (nonatomic) NSString *section;
@property (nonatomic) ZBSource *source;
@property (nonatomic) NSArray *_Nullable tag;
@property (nonatomic) NSString *uuid;
@property (nonatomic) NSString *version;
@property (readonly) BOOL isInstalled;
@property (readonly) BOOL isPaid;
@property (readonly) BOOL isOnWishlist;
- (instancetype)initFromSQLiteStatement:(sqlite3_stmt *)statement;
- (NSDate *_Nullable)installedDate;
- (void)setIconImageForImageView:(UIImageView * _Nonnull)imageView;
@end

NS_ASSUME_NONNULL_END
