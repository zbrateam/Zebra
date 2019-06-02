//
//  ZBColumn.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 1/6/2562 BE.
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
    ZBPackageColumnAuthor,
    ZBPackageColumnDepends,
    ZBPackageColumnConflicts,
    ZBPackageColumnProvides,
    ZBPackageColumnReplaces,
    ZBPackageColumnFilename,
    ZBPackageColumnIconURL,
    ZBPackageColumnRepoID
} ZBPackageColumn;

typedef enum {
    ZBUpdateColumnID = 0,
    ZBUpdateColumnVersion,
    ZBUpdateColumnIgnore
} ZBUpdateColumn;

typedef enum {
    ZBRepoColumnOrigin = 0,
    ZBRepoColumnDescription,
    ZBRepoColumnBaseFilename,
    ZBRepoColumnBaseURL,
    ZBRepoColumnSecure,
    ZBRepoColumnRepoID,
    ZBRepoColumnDef,
    ZBRepoColumnSuite,
    ZBRepoColumnComponents
} ZBRepoColumn;

#endif /* ZBColumn_h */
