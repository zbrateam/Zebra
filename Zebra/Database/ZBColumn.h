//
//  ZBColumn.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 1/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#ifndef ZBColumn_h
#define ZBColumn_h

typedef NS_ENUM(NSUInteger, ZBPackageColumn) {
    ZBPackageColumnAuthorEmail,
    ZBPackageColumnAuthorName,
    ZBPackageColumnConflicts,
    ZBPackageColumnDepends,
    ZBPackageColumnDepictionURL,
    ZBPackageColumnDescription,
    ZBPackageColumnDownloadSize,
    ZBPackageColumnEssential,
    ZBPackageColumnFilename,
    ZBPackageColumnHomepageURL,
    ZBPackageColumnIconURL,
    ZBPackageColumnIdentifier,
    ZBPackageColumnInstalledSize,
    ZBPackageColumnLastSeen,
    ZBPackageColumnMaintainerEmail,
    ZBPackageColumnMaintainerName,
    ZBPackageColumnName,
    ZBPackageColumnPriority,
    ZBPackageColumnProvides,
    ZBPackageColumnReplaces,
    ZBPackageColumnRole,
    ZBPackageColumnSection,
    ZBPackageColumnSHA256,
    ZBPackageColumnTag,
    ZBPackageColumnUUID,
    ZBPackageColumnVersion,
};

typedef NS_ENUM(NSUInteger, ZBSourceColumn) {
    ZBSourceColumnArchitectures,
    ZBSourceColumnArchiveType,
    ZBSourceColumnCodename,
    ZBSourceColumnDistribution,
    ZBSourceColumnLabel,
    ZBSourceColumnOrigin,
    ZBSourceColumnRemote,
    ZBSourceColumnDescription,
    ZBSourceColumnSuite,
    ZBSourceColumnURL,
    ZBSourceColumnUUID,
    ZBSourceColumnVersion,
};

#endif /* ZBColumn_h */
