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
    ZBPackageColumnShortDescription,
    ZBPackageColumnLongDescription,
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
    ZBPackageColumnIconURL,
    ZBPackageColumnRepoID,
    ZBPackageColumnLastSeen,
    ZBPackageColumnInstalledSize,
    ZBPackageColumnDownloadSize,
    ZBPackageColumnPriority,
    ZBPackageColumnEssential
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
    ZBSourceColumnRepoID
} ZBSourceColumn;

#endif /* ZBColumn_h */
