//
//  ZBColumn.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 1/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#ifndef ZBColumn_h
#define ZBColumn_h

typedef enum {
    ZBPackageColumnPackage = 0,
    ZBPackageColumnName,
    ZBPackageColumnVersion,
    ZBPackageColumnTagline,
    ZBPackageColumnDescription,
    ZBPackageColumnSection,
    ZBPackageColumnDepiction,
    ZBPackageColumnTag,
    ZBPackageColumnAuthorName,
    ZBPackageColumnAuthorEmail,
    ZBPackageColumnDepends,
    ZBPackageColumnConflicts,
    ZBPackageColumnProvides,
    ZBPackageColumnReplaces,
    ZBPackageColumnFilename,
    ZBPackageColumnIcon,
    ZBPackageColumnSourceID,
    ZBPackageColumnLastSeen,
    ZBPackageColumnInstalledSize,
    ZBPackageColumnDownloadSize,
    ZBPackageColumnPriority,
    ZBPackageColumnEssential,
    ZBPackageColumnSHA256,
    ZBPackageColumnHeader,
    ZBPackageColumnChangelog,
    ZBPackageColumnChangelogNotes,
    ZBPackageColumnHomepage,
    ZBPackageColumnPreviews,
    ZBPackageColumnMaintainerName,
    ZBPackageColumnMaintainerEmail
} ZBPackageColumn;

typedef enum {
    ZBUpdateColumnID = 0,
    ZBUpdateColumnVersion,
    ZBUpdateColumnIgnore
} ZBUpdateColumn;

typedef enum {
    ZBSourceColumnArchiveType = 0,
    ZBSourceColumnRepositoryURI,
    ZBSourceColumnDistribution,
    ZBSourceColumnComponents,
    ZBSourceColumnDescription,
    ZBSourceColumnOrigin,
    ZBSourceColumnLabel,
    ZBSourceColumnVersion,
    ZBSourceColumnSuite,
    ZBSourceColumnCodename,
    ZBSourceColumnArchitectures,
    ZBSourceColumnPaymentVendor,
    ZBSourceColumnBaseFilename,
    ZBSourceColumnSourceID
} ZBSourceColumn;

#endif /* ZBColumn_h */
