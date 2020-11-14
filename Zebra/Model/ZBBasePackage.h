//
//  ZBBasePackage.h
//  Zebra
//
//  Created by Wilson Styres on 10/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SQLite3;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZBPackageColumn) {
    // Base Package Columns
    ZBPackageColumnAuthorName,
    ZBPackageColumnDescription,
    ZBPackageColumnIdentifier,
    ZBPackageColumnLastSeen,
    ZBPackageColumnName,
    ZBPackageColumnVersion,
    ZBPackageColumnRole,
    ZBPackageColumnSection,
    ZBPackageColumnUUID,
    
    // Package Columns
    ZBPackageColumnAuthorEmail,
    ZBPackageColumnConflicts,
    ZBPackageColumnDepends,
    ZBPackageColumnDepictionURL,
    ZBPackageColumnDownloadSize,
    ZBPackageColumnEssential,
    ZBPackageColumnFilename,
    ZBPackageColumnHomepageURL,
    ZBPackageColumnIconURL,
    ZBPackageColumnInstalledSize,
    ZBPackageColumnMaintainerEmail,
    ZBPackageColumnMaintainerName,
    ZBPackageColumnPriority,
    ZBPackageColumnProvides,
    ZBPackageColumnReplaces,
    ZBPackageColumnSHA256,
    ZBPackageColumnTag,
    ZBPackageColumnSource,
    ZBPackageColumnStatus,
    ZBPackageColumnCount,
};

typedef char *_Nonnull *_Nonnull ZBControlSource;

@interface ZBBasePackage : NSObject
@property (nonatomic) NSString *authorName;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSDate   *lastSeen;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *packageDescription;
@property (nonatomic) int16_t role;
@property (nonatomic) NSString *section;
@property (nonatomic) NSString *uuid;
@property (nonatomic) NSString *version;

@property BOOL isOnWishlist;
- (instancetype)initFromSQLiteStatement:(sqlite3_stmt *)statement;
@end

NS_ASSUME_NONNULL_END
