//
//  ZBDatabaseManager.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#define PACKAGES_TABLE_NAME "packages"
#define SOURCES_TABLE_NAME "sources"

#import "ZBDatabaseManager.h"

@import SQLite3;
@import FirebaseAnalytics;

#import <ZBAppDelegate.h>
#import <ZBLog.h>
#import <Database/ZBColumn.h>
#import <Model/ZBSource.h>
#import <Model/ZBPackage.h>

typedef NS_ENUM(NSUInteger, ZBDatabaseStatementType) {
    ZBDatabaseStatementTypePackagesFromSource,
    ZBDatabaseStatementTypePackagesFromSourceAndSection,
    ZBDatabaseStatementTypeUUIDsFromSource,
    ZBDatabaseStatementTypePackageWithUUID,
    ZBDatabaseStatementTypeRemovePackageWithUUID,
    ZBDatabaseStatementTypeInsertPackage,
    ZBDatabaseStatementTypeSources,
    ZBDatabaseStatementTypeInsertSource,
    ZBDatabaseStatementTypeSectionReadout,
    ZBDatabaseStatementTypePackagesInSourceCount,
    ZBDatabaseStatementTypeCount
};

@interface ZBDatabaseManager () {
    sqlite3 *database;
    const char *databasePath;
    sqlite3_stmt **preparedStatements;
}
@end

@implementation ZBDatabaseManager

#pragma mark - Initializers

+ (instancetype)sharedInstance {
    static ZBDatabaseManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBDatabaseManager new];
    });
    return instance;
}

- (instancetype)init {
    return [self initWithPath:[ZBAppDelegate databaseLocation]];
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    
    if (self) {
        databasePath = [path UTF8String];
        if (![self connectToDatabase]) {
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc {
    if (database) {
        [self disconnectFromDatabase];
    }
}

#pragma mark - Opening and Closing the Database

- (BOOL)connectToDatabase {
    ZBLog(@"[Zebra] Initializing database at %s", databasePath);

    int result = [self openDB];
    if (result != SQLITE_OK) {
        ZBLog(@"[Zebra] Failed to open database at %s", databasePath);
    }

    if (result == SQLITE_OK) {
        result = [self initializePackagesTable];
        if (result != SQLITE_OK) {
            ZBLog(@"[Zebra] Failed to initialize packages table at %s", databasePath);
        }
    }

    if (result == SQLITE_OK) {
        result = [self initializeSourcesTable];
        if (result != SQLITE_OK) {
            ZBLog(@"[Zebra] Failed to initialize sources table at %s", databasePath);
        }
    }
    
    if (result == SQLITE_OK) {
        result = [self initializePreparedStatements];
        if (result != SQLITE_OK) {
            ZBLog(@"[Zebra] Failed to initialize prepared statements at %s", databasePath);
        }
    }

    if (result != SQLITE_OK) {
        ZBLog(@"[Zebra] Failed to initialize database at %s", databasePath);
        return NO;
    }

    return YES;
}

- (void)disconnectFromDatabase {
    if (preparedStatements) {
        for (unsigned int i = 0; i < ZBDatabaseStatementTypeCount; i++) {
            sqlite3_finalize(preparedStatements[i]);
        }
        free(preparedStatements);
        preparedStatements = NULL;
    }
    [self closeDB];
}

- (int)openDB {
    int flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FILEPROTECTION_COMPLETEUNLESSOPEN;
    return sqlite3_open_v2(databasePath, &database, flags, NULL);
}

- (int)closeDB {
    int result = SQLITE_ERROR;
    if (database) {
        result = sqlite3_close(database);
        if (result == SQLITE_OK) {
            database = NULL;
        } else {
            NSLog(@"[Zebra] Failed to close database path: %s", databasePath);
        }
    } else {
        NSLog(@"[Zebra] Attempt to close null notification database handle");
    }

    return result;
}

#pragma mark - Creating Tables

- (int)initializePackagesTable {
    NSString *createTableStatement = @"CREATE TABLE IF NOT EXISTS " PACKAGES_TABLE_NAME
                                      "(authorName TEXT, "
                                      "description TEXT, "
                                      "identifier TEXT, "
                                      "lastSeen DATE, "
                                      "name TEXT, "
                                      "version TEXT, "
                                      "section TEXT, "
                                      "uuid TEXT, "
                                      "authorEmail TEXT, "
                                      "conflicts TEXT, "
                                      "depends TEXT, "
                                      "depictionURL TEXT, "
                                      "downloadSize INTEGER, "
                                      "essential BOOLEAN, "
                                      "filename TEXT, "
                                      "homepageURL TEXT, "
                                      "iconURL TEXT, "
                                      "installedSize INTEGER, "
                                      "maintainerEmail TEXT, "
                                      "maintainerName TEXT, "
                                      "priority TEXT, "
                                      "provides TEXT, "
                                      "replaces TEXT, "
                                      "role INTEGER, "
                                      "sha256 TEXT, "
                                      "tag TEXT, "
                                      "source TEXT, "
                                      "FOREIGN KEY(source) REFERENCES " SOURCES_TABLE_NAME "(uuid) "
                                      "PRIMARY KEY(uuid)) "
                                      "WITHOUT ROWID;";
    int result = sqlite3_exec(database, [createTableStatement UTF8String], NULL, NULL, NULL);
    if (result != SQLITE_OK) {
        ZBLog(@"[Zebra] Failed to create packages table with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
    }

    if (result == SQLITE_OK) {
        NSString *createIndexStatement = @"CREATE INDEX IF NOT EXISTS uuid ON " PACKAGES_TABLE_NAME "(uuid);";
        result = sqlite3_exec(database, [createIndexStatement UTF8String], NULL, NULL, NULL);
        if (result != SQLITE_OK) {
            ZBLog(@"[Zebra] Failed to create uuid index on packages table with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
        }
    }
    return result;
}

- (int)initializeSourcesTable {
    NSString *createTableStatement = @"CREATE TABLE IF NOT EXISTS " SOURCES_TABLE_NAME
                                      "(architectures TEXT, "
                                      "archiveType TEXT, "
                                      "codename TEXT, "
                                      "components TEXT, "
                                      "distribution TEXT, "
                                      "label TEXT, "
                                      "origin TEXT, "
                                      "remote BOOLEAN, "
                                      "sourceDescription TEXT, "
                                      "suite TEXT, "
                                      "url TEXT, "
                                      "uuid TEXT, "
                                      "version TEXT, "
                                      "PRIMARY KEY(uuid)) "
                                      "WITHOUT ROWID;";
    int result = sqlite3_exec(database, [createTableStatement UTF8String], NULL, NULL, NULL);
    if (result != SQLITE_OK) {
        ZBLog(@"[Zebra] Failed to create sources table with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
    }

    if (result == SQLITE_OK) {
        NSString *createIndexStatement = @"CREATE INDEX IF NOT EXISTS uuid ON " SOURCES_TABLE_NAME "(uuid);";
        result = sqlite3_exec(database, [createIndexStatement UTF8String], NULL, NULL, NULL);
        if (result != SQLITE_OK) {
            ZBLog(@"[Zebra] Failed to create uuid index on sources table with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
        }
    }
    return result;
}

#pragma mark - Populating the database

- (void)updateLastUpdated {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastUpdatedDate"];
}

#pragma mark - Source management

- (int)sourceIDFromBaseFileName:(NSString *)bfn {
//    if ([bfn isEqualToString:@"_var_lib_dpkg_status"]) return 0;
//
//    if ([self openDatabase] == SQLITE_OK) {
//        sqlite3_stmt *statement = NULL;
//        int sourceID = -1;
//        if (sqlite3_prepare_v2(database, "SELECT REPOID FROM REPOS WHERE BASEFILENAME = ?", -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [bfn UTF8String], -1, SQLITE_TRANSIENT);
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                sourceID = sqlite3_column_int(statement, 0);
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//        return sourceID;
//    } else {
//        [self printDatabaseError];
//    }
    return -1;
}

- (int)sourceIDFromBaseURL:(NSString *)baseURL strict:(BOOL)strict {
//    if ([self openDatabase] == SQLITE_OK) {
//        sqlite3_stmt *statement = NULL;
//        int sourceID = -1;
//        if (sqlite3_prepare_v2(database, strict ? "SELECT REPOID FROM REPOS WHERE URI = ?" : "SELECT REPOID FROM REPOS WHERE URI LIKE ?", -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, strict ? [baseURL UTF8String] : [[NSString stringWithFormat:@"%%%@%%", baseURL] UTF8String], -1, SQLITE_TRANSIENT);
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                sourceID = sqlite3_column_int(statement, 0);
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//        return sourceID;
//    } else {
//        [self printDatabaseError];
//    }
    return -1;
}

- (ZBSource * _Nullable)sourceFromBaseURL:(NSString *)burl {
//    NSRange dividerRange = [burl rangeOfString:@"://"];
//    NSUInteger divide = NSMaxRange(dividerRange);
//    NSString *baseURL = divide > [burl length] ? burl : [burl substringFromIndex:divide];
//
//    if ([self openDatabase] == SQLITE_OK) {
//        sqlite3_stmt *statement = NULL;
//        ZBSource *source = nil;
//        if (sqlite3_prepare_v2(database, "SELECT * FROM REPOS WHERE BASEURL = ?", -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [baseURL UTF8String], -1, SQLITE_TRANSIENT);
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                source = [[ZBSource alloc] initWithSQLiteStatement:statement];
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//
//        return source;
//    } else {
//        [self printDatabaseError];
//    }
    return nil;
}

- (ZBSource * _Nullable)sourceFromBaseFilename:(NSString *)baseFilename {
//    if ([self openDatabase] == SQLITE_OK) {
//        sqlite3_stmt *statement = NULL;
//        ZBSource *source = nil;
//        if (sqlite3_prepare_v2(database, "SELECT * FROM REPOS WHERE BASEFILENAME = ?", -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [baseFilename UTF8String], -1, SQLITE_TRANSIENT);
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                source = [[ZBSource alloc] initWithSQLiteStatement:statement];
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//
//        return source;
//    } else {
//        [self printDatabaseError];
//    }
    return nil;
}

- (int)nextSourceID {
//    if ([self openDatabase] == SQLITE_OK) {
//        sqlite3_stmt *statement = NULL;
//        int sourceID = 0;
//        if (sqlite3_prepare_v2(database, "SELECT REPOID FROM REPOS ORDER BY REPOID DESC LIMIT 1", -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                sourceID = sqlite3_column_int(statement, 0);
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//        return sourceID + 1;
//    } else {
//        [self printDatabaseError];
//    }
    return -1;
}

- (int)numberOfPackagesInSource:(ZBSource * _Nullable)source section:(NSString * _Nullable)section enableFiltering:(BOOL)enableFiltering {
//    if ([self openDatabase] == SQLITE_OK) {
//        // FIXME: Use NSUserDefaults, variables binding
//        int packages = 0;
//        NSString *query = nil;
//        NSString *sourcePart = source ? [NSString stringWithFormat:@"REPOID = %d", [source sourceID]] : @"REPOID > 0";
//        if (section != NULL) {
//            query = [NSString stringWithFormat:@"SELECT COUNT(distinct package) FROM PACKAGES WHERE SECTION = \'%@\' AND %@", section, sourcePart];
//        } else {
//            query = [NSString stringWithFormat:@"SELECT SECTION, AUTHOR, REPOID FROM PACKAGES WHERE %@ GROUP BY PACKAGE", sourcePart];
//        }
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                if (section == NULL) {
//                    if (!enableFiltering) {
//                        ++packages;
//                    } else {
//                        const char *packageSection = (const char *)sqlite3_column_text(statement, 1);
//                        const char *packageAuthor = (const char *)sqlite3_column_text(statement, 2);
//
//                        if (packageAuthor != 0) {
//                            int sourceID = sqlite3_column_int(statement, 3);
//                            NSArray *split = [ZBUtils splitNameAndEmail:[NSString stringWithUTF8String:packageAuthor]];
//                            NSString *authorName = split.count > 0 ? split[0] : NULL;
//                            NSString *authorEmail = split.count > 1 ? split[1] : NULL;
//                            if (![ZBSettings isSectionFiltered:packageSection != 0 ? [NSString stringWithUTF8String:packageSection] : @"Uncategorized" forSource:[[ZBSourceManager sharedInstance] sourceMatchingSourceID:sourceID]] && ![ZBSettings isAuthorBlocked:authorName email:authorEmail])
//                                ++packages;
//                        }
//                        else {
//                            ++packages; // We can't filter this package as it has no author
//                        }
//                    }
//                } else {
//                    packages = sqlite3_column_int(statement, 0);
//                    break;
//                }
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//        return packages;
//    } else {
//        [self printDatabaseError];
//    }
    return -1;
}

- (int)numberOfPackagesInSource:(ZBSource * _Nullable)source section:(NSString * _Nullable)section {
    return [self numberOfPackagesInSource:source section:section enableFiltering:NO];
}

- (ZBSource * _Nullable)sourceFromSourceID:(int)sourceID {
//    if (sourceID == 0) return [ZBSource localSource];
//
//    if ([self openDatabase] == SQLITE_OK) {
//        ZBSource *source;
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, "SELECT * FROM REPOS WHERE REPOID = ?", -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_int(statement, 1, sourceID);
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                ZBSource *potential = [[ZBSource alloc] initWithSQLiteStatement:statement];
//                if (potential) source = potential;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//
//        return source;
//    }
//
//    [self printDatabaseError];
    return nil;
}

- (NSSet <ZBSource *> * _Nullable)sourcesWithPaymentEndpoint {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableSet *sources = [NSMutableSet new];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, "SELECT * FROM REPOS WHERE VENDOR NOT NULL;", -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                ZBSource *source = [[ZBSource alloc] initWithSQLiteStatement:statement];
//
//                [sources addObject:source];
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//
//        return sources;
//    }
//
//    [self printDatabaseError];
    return nil;
}

- (void)updateURIForSource:(ZBSource *)source {
//    if ([self openDatabase] == SQLITE_OK) {
//        sqlite3_stmt *statement = NULL;
//
//        if (sqlite3_prepare_v2(database, "UPDATE REPOS SET URI = ? WHERE REPOID = ?;", -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [source.repositoryURI UTF8String], -1, SQLITE_TRANSIENT);
//            sqlite3_bind_int(statement, 2, [source sourceID]);
//
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//    } else {
//        [self printDatabaseError];
//    }
}

- (void)deleteSource:(ZBSource *)source {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSString *packageQuery = [NSString stringWithFormat:@"DELETE FROM PACKAGES WHERE REPOID = %d", [source sourceID]];
//        NSString *sourceQuery = [NSString stringWithFormat:@"DELETE FROM REPOS WHERE REPOID = %d", [source sourceID]];
//
//        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
//        sqlite3_exec(database, [packageQuery UTF8String], NULL, NULL, NULL);
//        sqlite3_exec(database, [sourceQuery UTF8String], NULL, NULL, NULL);
//        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
//
//        [self closeDatabase];
//    } else {
//        [self printDatabaseError];
//    }
}

- (void)cancelUpdates:(id <ZBDatabaseDelegate>)delegate {
//    [self setDatabaseBeingUpdated:NO];
//    [self setHaltDatabaseOperations:YES];
////    [self.downloadManager stopAllDownloads];
//    [self bulkDatabaseCompletedUpdate];
//    [self removeDatabaseDelegate:delegate];
}

- (NSURL * _Nullable)paymentVendorURLForSource:(ZBSource *)source {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSString *query = [NSString stringWithFormat:@"SELECT VENDOR FROM REPOS WHERE REPOID = %d", [source sourceID]];
//        sqlite3_stmt *statement = NULL;
//
//        NSString *vendorURL = nil;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_step(statement);
//
//            const char *vendorChars = (const char *)sqlite3_column_text(statement, 0);
//            vendorURL = vendorChars ? [NSString stringWithUTF8String:vendorChars] : NULL;
//        }
//        else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//        if (vendorURL) {
//            return [NSURL URLWithString:vendorURL];
//        }
//    }
    return NULL;
}

#pragma mark - Package management

- (NSArray <ZBPackage *> * _Nullable)packagesFromSource:(ZBSource * _Nullable)source inSection:(NSString * _Nullable)section numberOfPackages:(int)limit startingAt:(int)start enableFiltering:(BOOL)enableFiltering {
    
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *packages = [NSMutableArray new];
//        NSString *query = nil;
//
//        if (section == NULL) {
//            NSString *sourcePart = source ? [NSString stringWithFormat:@"WHERE REPOID = %d", [source sourceID]] : @"WHERE REPOID > 0";
//            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES %@ ORDER BY LASTSEEN DESC LIMIT %d OFFSET %d", sourcePart, limit, start];
//        } else {
//            NSString *sourcePart = source ? [NSString stringWithFormat:@"AND REPOID = %d", [source sourceID]] : @"AND REPOID > 0";
//
//            NSString *sectionString;
//            if ([section containsString:@" "]) {
//                sectionString = [NSString stringWithFormat:@"SECTION = \'%@\' OR SECTION = \'%@\'", section, [section stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
//            }
//            else if ([section containsString:@"_"]) {
//                sectionString = [NSString stringWithFormat:@"SECTION = \'%@\' OR SECTION = \'%@\'", section, [section stringByReplacingOccurrencesOfString:@"_" withString:@" "]];
//            }
//            else {
//                sectionString = [NSString stringWithFormat:@"SECTION = \'%@\'", section];
//            }
//
//            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE %@ %@ LIMIT %d OFFSET %d", sectionString, sourcePart, limit, start];
//        }
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//
//                if (section == NULL && enableFiltering && [ZBSettings isPackageFiltered:package])
//                    continue;
//
//                [packages addObject:package];
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//
//        return [self cleanUpDuplicatePackages:packages];
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSArray <ZBPackage *> * _Nullable)packagesFromSource:(ZBSource * _Nullable)source inSection:(NSString * _Nullable)section numberOfPackages:(int)limit startingAt:(int)start {
    return [self packagesFromSource:source inSection:section numberOfPackages:limit startingAt:start enableFiltering:NO];
}

- (NSMutableArray <ZBPackage *> * _Nullable)installedPackages:(BOOL)includeVirtualDependencies {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *installedPackageIdentifiers = [NSMutableArray new];
//        NSMutableArray *installedPackages = [NSMutableArray new];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, includeVirtualDependencies ? "SELECT * FROM PACKAGES WHERE REPOID < 1;" : "SELECT * FROM PACKAGES WHERE REPOID = 0;", -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                const char *packageIDChars =        (const char *)sqlite3_column_text(statement, ZBPackageColumnPackage);
//                const char *versionChars =          (const char *)sqlite3_column_text(statement, ZBPackageColumnVersion);
//                NSString *packageID = [NSString stringWithUTF8String:packageIDChars];
//                NSString *packageVersion = [NSString stringWithUTF8String:versionChars];
//                ZBPackage *package = [self packageForID:packageID equalVersion:packageVersion];
//                if (package) {
//                    package.version = packageVersion;
//                    [installedPackageIdentifiers addObject:package.identifier];
//                    [installedPackages addObject:package];
//                }
//            }
//        } else {
//            [self printDatabaseError];
//        }
//
//        installedPackageIDs = installedPackageIdentifiers;
//
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//
//        return installedPackages;
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSDictionary <NSString *, NSArray <NSDictionary *> *> *)installedPackagesList {
//    NSMutableArray *installedPackages = [NSMutableArray new];
//    NSMutableArray *virtualPackages = [NSMutableArray new];
//
//    for (ZBPackage *package in [self installedPackages:YES]) {
//        NSDictionary *installedPackage = @{@"identifier": [package identifier], @"version": [package version]};
//        [installedPackages addObject:installedPackage];
//
//        for (NSString *virtualPackageLine in [package provides]) {
//            NSArray *comps = [ZBDependencyResolver separateVersionComparison:virtualPackageLine];
//            NSDictionary *virtualPackage = @{@"identifier": comps[0], @"version": comps[2]};
//
//            [virtualPackages addObject:virtualPackage];
//        }
//    }
//
//    return @{@"installed": installedPackages, @"virtual": virtualPackages};
    return NULL;
}

- (NSMutableArray <ZBPackage *> *)packagesWithIgnoredUpdates {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *packagesWithIgnoredUpdates = [NSMutableArray new];
//        NSMutableArray *irrelevantPackages = [NSMutableArray new];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, "SELECT * FROM UPDATES WHERE IGNORE = 1;", -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                const char *identifierChars = (const char *)sqlite3_column_text(statement, ZBUpdateColumnID);
//                const char *versionChars = (const char *)sqlite3_column_text(statement, ZBUpdateColumnVersion);
//                NSString *identifier = [NSString stringWithUTF8String:identifierChars];
//                ZBPackage *package = nil;
//                if (versionChars != 0) {
//                    NSString *version = [NSString stringWithUTF8String:versionChars];
//
//                    package = [self packageForID:identifier equalVersion:version];
//                    if (package != NULL) {
//                        [packagesWithIgnoredUpdates addObject:package];
//                    }
//                }
//                if (![self packageIDIsInstalled:identifier version:nil]) {
//                    // We don't need ignored updates from packages we don't have them installed
//                    [irrelevantPackages addObject:[NSString stringWithFormat:@"'%@'", identifier]];
//                    if (package) {
//                        [packagesWithIgnoredUpdates removeObject:package];
//                    }
//                }
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//
//        if (irrelevantPackages.count) {
//            sqlite3_exec(database, [[NSString stringWithFormat:@"DELETE FROM UPDATES WHERE PACKAGE IN (%@)", [irrelevantPackages componentsJoinedByString:@", "]] UTF8String], NULL, 0, NULL);
//        }
//
//        [self closeDatabase];
//
//        return packagesWithIgnoredUpdates;
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSMutableArray <ZBPackage *> * _Nullable)packagesWithUpdates {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *packagesWithUpdates = [NSMutableArray new];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, "SELECT * FROM UPDATES WHERE IGNORE = 0;", -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                const char *identifierChars = (const char *)sqlite3_column_text(statement, ZBUpdateColumnID);
//                const char *versionChars = (const char *)sqlite3_column_text(statement, ZBUpdateColumnVersion);
//                NSString *identifier = [NSString stringWithUTF8String:identifierChars];
//                if (versionChars != 0) {
//                    NSString *version = [NSString stringWithUTF8String:versionChars];
//
//                    ZBPackage *package = [self packageForID:identifier equalVersion:version];
//                    if (package != NULL && [upgradePackageIDs containsObject:package.identifier]) {
//                        [packagesWithUpdates addObject:package];
//                    }
//                } else if ([upgradePackageIDs containsObject:identifier]) {
//                    [upgradePackageIDs removeObject:identifier];
//                }
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//        return packagesWithUpdates;
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSArray * _Nullable)searchForPackageName:(NSString *)name fullSearch:(BOOL)fullSearch {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *searchResults = [NSMutableArray new];
//        NSString *columns = fullSearch ? @"*" : @"PACKAGE, NAME, VERSION, REPOID, SECTION, ICON, TAG";
//        NSString *limit = fullSearch ? @";" : @" LIMIT 30;";
//        NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM PACKAGES WHERE NAME LIKE \'%%%@\%%\' AND REPOID > -1 ORDER BY (CASE WHEN NAME = \'%@\' THEN 1 WHEN NAME LIKE \'%@%%\' THEN 2 ELSE 3 END), NAME COLLATE NOCASE%@", columns, name, name, name, limit];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                if (fullSearch) {
//                    ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//
//                    [searchResults addObject:package];
//                }
//                else {
//                    ZBProxyPackage *proxyPackage = [[ZBProxyPackage alloc] initWithSQLiteStatement:statement];
//
//                    const char *sectionChars = (const char *)sqlite3_column_text(statement, 4);
//                    const char *iconURLChars = (const char *)sqlite3_column_text(statement, 5);
//                    const char *tagChars     = (const char *)sqlite3_column_text(statement, 6);
//
//                    NSString *section = sectionChars != 0 ? [NSString stringWithUTF8String:sectionChars] : NULL;
//                    NSString *iconURLString = iconURLChars != 0 ? [NSString stringWithUTF8String:iconURLChars] : NULL;
//                    NSURL *iconURL = iconURLString ? [NSURL URLWithString:iconURLString] : nil;
//                    NSArray *tags = tagChars != 0 ? [[NSString stringWithUTF8String:tagChars] componentsSeparatedByString:@", "] : nil;
//                    if (tags.count == 1 && [tags[0] containsString:@","]) {
//                        tags = [tags[0] componentsSeparatedByString:@","];
//                    }
//
//                    if (section) proxyPackage.section = section;
//                    if (iconURL) proxyPackage.iconURL = iconURL;
//                    if (tags)    proxyPackage.tags = tags;
//
//                    [searchResults addObject:proxyPackage];
//                }
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//
//        return [self cleanUpDuplicatePackages:searchResults];
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSArray <NSArray <NSString *> *> * _Nullable)searchForAuthorName:(NSString *)authorName fullSearch:(BOOL)fullSearch {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *searchResults = [NSMutableArray new];
//        NSString *limit = fullSearch ? @";" : @" LIMIT 30;";
//        NSString *query = [NSString stringWithFormat:@"SELECT AUTHOR FROM PACKAGES WHERE AUTHOR LIKE \'%%%@\%%\' AND REPOID > -1 GROUP BY AUTHOR ORDER BY (CASE WHEN AUTHOR = \'%@\' THEN 1 WHEN AUTHOR LIKE \'%@%%\' THEN 2 ELSE 3 END) COLLATE NOCASE%@", authorName, authorName, authorName, limit];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                const char *authorChars = (const char *)sqlite3_column_text(statement, 0);
//
//                if (authorChars != 0) {
//                    NSString *author = [NSString stringWithUTF8String:authorChars];
//
//                    NSArray *split = [ZBUtils splitNameAndEmail:author];
//                    NSString *name = split.count > 0 ? split[0] : NULL;
//                    NSString *email = split.count > 1 ? split[1] : NULL;
//
//                    if (name || email) {
//                        [searchResults addObject:@[name ?: email, email ?: name]];
//                    }
//                }
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//
//        return searchResults;
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSArray <NSString *> * _Nullable)searchForAuthorFromEmail:(NSString *)authorEmail fullSearch:(BOOL)fullSearch {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *searchResults = [NSMutableArray new];
//        NSString *limit = fullSearch ? @";" : @" LIMIT 30;";
//        NSString *query = [NSString stringWithFormat:@"SELECT AUTHOR FROM PACKAGES WHERE AUTHOR LIKE \'%%%@\%%\' AND REPOID > -1 GROUP BY AUTHOR COLLATE NOCASE%@", authorEmail, limit];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                const char *authorChars = (const char *)sqlite3_column_text(statement, 0);
//
//                if (authorChars != 0) {
//                    NSString *author = [NSString stringWithUTF8String:authorChars];
//
//                    NSArray *split = [ZBUtils splitNameAndEmail:author];
//                    NSString *name = split.count > 0 ? split[0] : NULL;
//                    NSString *email = split.count > 1 ? split[1] : NULL;
//
//                    if (name && email) {
//                        [searchResults addObject:@[name, email]];
//                    }
//                }
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//
//        return searchResults;
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSArray <ZBPackage *> * _Nullable)packagesFromIdentifiers:(NSArray <NSString *> *)requestedPackages {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *packages = [NSMutableArray new];
//        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE IN ('\%@') ORDER BY NAME COLLATE NOCASE ASC", [requestedPackages componentsJoinedByString:@"','"]];
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [[requestedPackages componentsJoinedByString:@"','"] UTF8String], -1, SQLITE_TRANSIENT);
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//
//                [packages addObject:package];
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//
//        return [self cleanUpDuplicatePackages:packages];
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (ZBPackage * _Nullable)packageFromProxy:(ZBProxyPackage *)proxy {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE = \'%@\' AND VERSION = \'%@\' AND REPOID = %d LIMIT 1", proxy.identifier, proxy.version, proxy.sourceID];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_step(statement);
//
//            ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//            sqlite3_finalize(statement);
//            [self closeDatabase];
//
//            return package;
//        }
//        else {
//            [self printDatabaseError];
//            sqlite3_finalize(statement);
//            [self closeDatabase];
//        }
//    }
//    else {
//        [self printDatabaseError];
//    }
    return NULL;
}

#pragma mark - Package status

- (BOOL)packageIDHasUpdate:(NSString *)packageIdentifier {
//    if ([upgradePackageIDs count] != 0) {
//        return [upgradePackageIDs containsObject:packageIdentifier];
//    } else {
//        if ([self openDatabase] == SQLITE_OK) {
//            BOOL packageIsInstalled = NO;
//            sqlite3_stmt *statement = NULL;
//            if (sqlite3_prepare_v2(database, "SELECT PACKAGE FROM UPDATES WHERE PACKAGE = ? AND IGNORE = 0 LIMIT 1;", -1, &statement, nil) == SQLITE_OK) {
//                sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
//                while (sqlite3_step(statement) == SQLITE_ROW) {
//                    packageIsInstalled = YES;
//                    break;
//                }
//            } else {
//                [self printDatabaseError];
//            }
//            sqlite3_finalize(statement);
//            [self closeDatabase];
//
//            return packageIsInstalled;
//        } else {
//            [self printDatabaseError];
//        }
//        return NO;
//    }
    return NO;
}

- (BOOL)packageHasUpdate:(ZBPackage *)package {
    return [self packageIDHasUpdate:package.identifier];
}

- (BOOL)packageIDIsInstalled:(NSString *)packageIdentifier version:(NSString *_Nullable)version {
//    if (version == NULL && [installedPackageIDs count] != 0) {
//        BOOL packageIsInstalled = [[installedPackageIDs copy] containsObject:packageIdentifier];
//        ZBLog(@"[Zebra] [installedPackageIDs] Is %@ (version: %@) installed? : %d", packageIdentifier, version, packageIsInstalled);
//        if (packageIsInstalled) {
//            return packageIsInstalled;
//        }
//    }
//    if ([self openDatabase] == SQLITE_OK) {
//        NSString *query;
//
//        if (version != NULL) {
//            query = [NSString stringWithFormat:@"SELECT PACKAGE FROM PACKAGES WHERE PACKAGE = \'%@\' AND VERSION = \'%@\' AND REPOID < 1 LIMIT 1;", packageIdentifier, version];
//        } else {
//            query = [NSString stringWithFormat:@"SELECT PACKAGE FROM PACKAGES WHERE PACKAGE = \'%@\' AND REPOID < 1 LIMIT 1;", packageIdentifier];
//        }
//
//        BOOL packageIsInstalled = NO;
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                packageIsInstalled = YES;
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//
//        ZBLog(@"[Zebra] Is %@ (version: %@) installed? : %d", packageIdentifier, version, packageIsInstalled);
//        return packageIsInstalled;
//    } else {
//        [self printDatabaseError];
//    }
    return NO;
}

- (BOOL)packageIsInstalled:(ZBPackage *)package versionStrict:(BOOL)strict {
    return [self packageIDIsInstalled:package.identifier version:strict ? package.version : NULL];
}

- (BOOL)packageIDIsAvailable:(NSString *)packageIdentifier version:(NSString *_Nullable)version {
//    if ([self openDatabase] == SQLITE_OK) {
//        BOOL packageIsAvailable = NO;
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, "SELECT PACKAGE FROM PACKAGES WHERE PACKAGE = ? AND REPOID > 0 LIMIT 1;", -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                packageIsAvailable = YES;
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//        return packageIsAvailable;
//    } else {
//        [self printDatabaseError];
//    }
    return NO;
}

- (BOOL)packageIsAvailable:(ZBPackage *)package versionStrict:(BOOL)strict {
    return [self packageIDIsAvailable:package.identifier version:strict ? package.version : NULL];
}

- (ZBPackage * _Nullable)packageForID:(NSString *)identifier equalVersion:(NSString *)version {
//    if ([self openDatabase] == SQLITE_OK) {
//        ZBPackage *package = nil;
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, "SELECT * FROM PACKAGES WHERE PACKAGE = ? AND VERSION = ? LIMIT 1;", -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [identifier UTF8String], -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 2, [version UTF8String], -1, SQLITE_TRANSIENT);
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//        return package;
//    } else {
//        [self printDatabaseError];
//    }
    return nil;
}

- (BOOL)areUpdatesIgnoredForPackage:(ZBPackage *)package {
    return [self areUpdatesIgnoredForPackageIdentifier:[package identifier]];
}

- (BOOL)areUpdatesIgnoredForPackageIdentifier:(NSString *)identifier {
//    if ([self openDatabase] == SQLITE_OK) {
//        BOOL ignored = NO;
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, "SELECT IGNORE FROM UPDATES WHERE PACKAGE = ? LIMIT 1;", -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [identifier UTF8String], -1, SQLITE_TRANSIENT);
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                if (sqlite3_column_int(statement, 0) == 1)
//                    ignored = YES;
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//        return ignored;
//    } else {
//        [self printDatabaseError];
//    }
    return NO;
}

- (void)setUpdatesIgnored:(BOOL)ignore forPackage:(ZBPackage *)package {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSString *query = [NSString stringWithFormat:@"REPLACE INTO UPDATES(PACKAGE, VERSION, IGNORE) VALUES(\'%@\', \'%@\', %d);", package.identifier, package.version, ignore ? 1 : 0];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                break;
//            }
//        } else {
//            NSLog(@"[Zebra] Error preparing setting package ignore updates statement: %s", sqlite3_errmsg(database));
//        }
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//    } else {
//        [self printDatabaseError];
//    }
}

#pragma mark - Package lookup

- (ZBPackage * _Nullable)packageThatProvides:(NSString *)identifier thatSatisfiesComparison:(NSString *)comparison ofVersion:(NSString *)version {
    return [self packageThatProvides:identifier thatSatisfiesComparison:comparison ofVersion:version thatIsNot:NULL];
}

- (ZBPackage * _Nullable)packageThatProvides:(NSString *)packageIdentifier thatSatisfiesComparison:(NSString *)comparison ofVersion:(NSString *)version thatIsNot:(ZBPackage * _Nullable)exclude {
//    if ([self openDatabase] == SQLITE_OK) {
//        packageIdentifier = [packageIdentifier lowercaseString];
//
//        const char *query;
//        const char *firstSearchTerm = [[NSString stringWithFormat:@"%%, %@ (%%", packageIdentifier] UTF8String];
//        const char *secondSearchTerm = [[NSString stringWithFormat:@"%%, %@, %%", packageIdentifier] UTF8String];
//        const char *thirdSearchTerm = [[NSString stringWithFormat:@"%@ (%%", packageIdentifier] UTF8String];
//        const char *fourthSearchTerm = [[NSString stringWithFormat:@"%@, %%", packageIdentifier] UTF8String];
//        const char *fifthSearchTerm = [[NSString stringWithFormat:@"%%, %@", packageIdentifier] UTF8String];
//        const char *sixthSearchTerm = [[NSString stringWithFormat:@"%%| %@", packageIdentifier] UTF8String];
//        const char *seventhSearchTerm = [[NSString stringWithFormat:@"%%, %@ |%%", packageIdentifier] UTF8String];
//        const char *eighthSearchTerm = [[NSString stringWithFormat:@"%@ |%%", packageIdentifier] UTF8String];
//
//        if (exclude) {
//            query = "SELECT * FROM PACKAGES WHERE PACKAGE != ? AND REPOID > 0 AND (PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ?) AND REPOID > 0 LIMIT 1;";
//        }
//        else {
//            query = "SELECT * FROM PACKAGES WHERE REPOID > 0 AND (PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ?) LIMIT 1;";
//        }
//
//        NSMutableArray <ZBPackage *> *packages = [NSMutableArray new];
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK) {
//            if (exclude) {
//                sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
//            }
//            sqlite3_bind_text(statement, exclude ? 2 : 1, firstSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 3 : 2, secondSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 4 : 3, thirdSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 5 : 4, fourthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 6 : 5, fifthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 7 : 6, sixthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 8 : 7, seventhSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 9 : 8, eighthSearchTerm, -1, SQLITE_TRANSIENT);
//
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                const char *providesLine = (const char *)sqlite3_column_text(statement, ZBPackageColumnProvides);
//                if (providesLine != 0) {
//                    NSString *provides = [[NSString stringWithUTF8String:providesLine] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//                    NSArray *virtualPackages = [provides componentsSeparatedByString:@","];
//
//                    for (NSString *virtualPackage in virtualPackages) {
//                        NSArray *versionComponents = [ZBDependencyResolver separateVersionComparison:[virtualPackage stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
//                        if ([versionComponents[0] isEqualToString:packageIdentifier] &&
//                            ([versionComponents[2] isEqualToString:@"0:0"] || [ZBDependencyResolver doesVersion:versionComponents[2] satisfyComparison:comparison ofVersion:version])) {
//                            ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//                            [packages addObject:package];
//                            break;
//                        }
//                    }
//                }
//            }
//        } else {
//            [self printDatabaseError];
//            return NULL;
//        }
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//        return [packages count] ? packages[0] : NULL; //Returns the first package in the array, we could use interactive dependency resolution in the future
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (ZBPackage * _Nullable)installedPackageThatProvides:(NSString *)identifier thatSatisfiesComparison:(NSString *)comparison ofVersion:(NSString *)version {
    return [self installedPackageThatProvides:identifier thatSatisfiesComparison:comparison ofVersion:version thatIsNot:NULL];
}

- (ZBPackage * _Nullable)installedPackageThatProvides:(NSString *)packageIdentifier thatSatisfiesComparison:(NSString *)comparison ofVersion:(NSString *)version thatIsNot:(ZBPackage *_Nullable)exclude {
//    if ([self openDatabase] == SQLITE_OK) {
//        const char *query;
//        const char *firstSearchTerm = [[NSString stringWithFormat:@"%%, %@ (%%", packageIdentifier] UTF8String];
//        const char *secondSearchTerm = [[NSString stringWithFormat:@"%%, %@, %%", packageIdentifier] UTF8String];
//        const char *thirdSearchTerm = [[NSString stringWithFormat:@"%@ (%%", packageIdentifier] UTF8String];
//        const char *fourthSearchTerm = [[NSString stringWithFormat:@"%@, %%", packageIdentifier] UTF8String];
//        const char *fifthSearchTerm = [[NSString stringWithFormat:@"%%, %@", packageIdentifier] UTF8String];
//        const char *sixthSearchTerm = [[NSString stringWithFormat:@"%%| %@", packageIdentifier] UTF8String];
//        const char *seventhSearchTerm = [[NSString stringWithFormat:@"%%, %@ |%%", packageIdentifier] UTF8String];
//        const char *eighthSearchTerm = [[NSString stringWithFormat:@"%@ |%%", packageIdentifier] UTF8String];
//
//        if (exclude) {
//            query = "SELECT * FROM PACKAGES WHERE PACKAGE != ? AND REPOID = 0 AND (PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ?) AND REPOID > 0 LIMIT 1;";
//        }
//        else {
//            query = "SELECT * FROM PACKAGES WHERE REPOID = 0 AND (PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ?) LIMIT 1;";
//        }
//
//        NSMutableArray <ZBPackage *> *packages = [NSMutableArray new];
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK) {
//            if (exclude) {
//                sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
//            }
//            sqlite3_bind_text(statement, exclude ? 2 : 1, firstSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 3 : 2, secondSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 4 : 3, thirdSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 5 : 4, fourthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 6 : 5, fifthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 7 : 6, sixthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 8 : 7, seventhSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, exclude ? 9 : 8, eighthSearchTerm, -1, SQLITE_TRANSIENT);
//
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//                [packages addObject:package];
//            }
//        } else {
//            [self printDatabaseError];
//            return NULL;
//        }
//        sqlite3_finalize(statement);
//
//        for (ZBPackage *package in packages) {
//            //If there is a comparison and a version then we return the first package that satisfies this comparison, otherwise we return the first package we see
//            //(this also sets us up better later for interactive dependency resolution)
//            if (comparison && version && [ZBDependencyResolver doesPackage:package satisfyComparison:comparison ofVersion:version]) {
//                [self closeDatabase];
//                return package;
//            }
//            else if (!comparison || !version) {
//                [self closeDatabase];
//                return package;
//            }
//        }
//
//        [self closeDatabase];
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (ZBPackage * _Nullable)packageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version {
    return [self packageForIdentifier:identifier thatSatisfiesComparison:comparison ofVersion:version includeVirtualPackages:YES];
}

- (ZBPackage * _Nullable)packageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version includeVirtualPackages:(BOOL)checkVirtual {
//    if ([self openDatabase] == SQLITE_OK) {
//        ZBPackage *package = nil;
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, "SELECT * FROM PACKAGES WHERE PACKAGE = ? COLLATE NOCASE AND REPOID > 0 LIMIT 1;", -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [identifier UTF8String], -1, SQLITE_TRANSIENT);
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//
//        // Only try to resolve "Provides" if we can't resolve the normal package.
//        if (checkVirtual && package == NULL) {
//            package = [self packageThatProvides:identifier thatSatisfiesComparison:comparison ofVersion:version]; //there is a scenario here where two packages that provide a package could be found (ex: anemone, snowboard, and ithemer all provide winterboard) we need to ask the user which one to pick.
//        }
//
//        if (package != NULL) {
//            NSArray *otherVersions = [self allVersionsForPackage:package];
//            if (version != NULL && comparison != NULL) {
//                if ([otherVersions count] > 1) {
//                    for (ZBPackage *package in otherVersions) {
//                        if ([ZBDependencyResolver doesPackage:package satisfyComparison:comparison ofVersion:version]) {
//                            [self closeDatabase];
//                            return package;
//                        }
//                    }
//
//                    [self closeDatabase];
//                    return NULL;
//                }
//                [self closeDatabase];
//                return [ZBDependencyResolver doesPackage:otherVersions[0] satisfyComparison:comparison ofVersion:version] ? otherVersions[0] : NULL;
//            }
//            return otherVersions[0];
//        }
//
//        [self closeDatabase];
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (ZBPackage * _Nullable)installedPackageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version {
    return [self installedPackageForIdentifier:identifier thatSatisfiesComparison:comparison ofVersion:version includeVirtualPackages:YES thatIsNot:NULL];
}

- (ZBPackage * _Nullable)installedPackageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version includeVirtualPackages:(BOOL)checkVirtual {
    return [self installedPackageForIdentifier:identifier thatSatisfiesComparison:comparison ofVersion:version includeVirtualPackages:checkVirtual thatIsNot:NULL];
}

- (ZBPackage * _Nullable)installedPackageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version includeVirtualPackages:(BOOL)checkVirtual thatIsNot:(ZBPackage *_Nullable)exclude {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSString *query;
//        if (exclude) {
//            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE = '\%@\' COLLATE NOCASE AND REPOID = 0 AND PACKAGE != '\%@\' LIMIT 1;", identifier, [exclude identifier]];
//        }
//        else {
//            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE = '\%@\' COLLATE NOCASE AND REPOID = 0 LIMIT 1;", identifier];
//        }
//
//        ZBPackage *package;
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//
//        // Only try to resolve "Provides" if we can't resolve the normal package.
//        if (checkVirtual && package == NULL) {
//            package = [self installedPackageThatProvides:identifier thatSatisfiesComparison:comparison ofVersion:version thatIsNot:exclude]; //there is a scenario here where two packages that provide a package could be found (ex: anemone, snowboard, and ithemer all provide winterboard) we need to ask the user which one to pick.
//        }
//
//        if (package != NULL) {
//            [self closeDatabase];
//            if (version != NULL && comparison != NULL) {
//                return [ZBDependencyResolver doesPackage:package satisfyComparison:comparison ofVersion:version] ? package : NULL;
//            }
//            return package;
//        }
//
//        [self closeDatabase];
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSArray * _Nullable)allVersionsForPackage:(ZBPackage *)package {
    return [self allVersionsForPackageID:package.identifier inSource:NULL];
}

- (NSArray * _Nullable)allVersionsForPackageID:(NSString *)packageIdentifier {
    return [self allVersionsForPackageID:packageIdentifier inSource:NULL];
}

- (NSArray * _Nullable)allVersionsForPackage:(ZBPackage *)package inSource:(ZBSource *_Nullable)source {
    return [self allVersionsForPackageID:package.identifier inSource:source];
}

- (NSArray * _Nullable)allVersionsForPackageID:(NSString *)packageIdentifier inSource:(ZBSource *_Nullable)source {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *allVersions = [NSMutableArray new];
//
//        NSString *query;
//        sqlite3_stmt *statement = NULL;
//        if (source != NULL) {
//            query = @"SELECT * FROM PACKAGES WHERE PACKAGE = ? AND REPOID = ?;";
//        }
//        else {
//            query = @"SELECT * FROM PACKAGES WHERE PACKAGE = ?;";
//        }
//
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
//            if (source != NULL) {
//                sqlite3_bind_int(statement, 2, [source sourceID]);
//            }
//        }
//        while (sqlite3_step(statement) == SQLITE_ROW) {
//            ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//
//            [allVersions addObject:package];
//        }
//        sqlite3_finalize(statement);
//
//        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
//        NSArray *sorted = [allVersions sortedArrayUsingDescriptors:@[sort]];
//        [self closeDatabase];
//
//        return sorted;
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSArray * _Nullable)otherVersionsForPackage:(ZBPackage *)package {
    return [self otherVersionsForPackageID:package.identifier version:package.version];
}

- (NSArray * _Nullable)otherVersionsForPackageID:(NSString *)packageIdentifier version:(NSString *)version {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *otherVersions = [NSMutableArray new];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, "SELECT * FROM PACKAGES WHERE PACKAGE = ? AND VERSION != ?;", -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 2, [version UTF8String], -1, SQLITE_TRANSIENT);
//        }
//        while (sqlite3_step(statement) == SQLITE_ROW) {
//            int sourceID = sqlite3_column_int(statement, ZBPackageColumnSourceID);
//            if (sourceID > 0) {
//                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//
//                [otherVersions addObject:package];
//            }
//        }
//        sqlite3_finalize(statement);
//
//        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
//        NSArray *sorted = [otherVersions sortedArrayUsingDescriptors:@[sort]];
//        [self closeDatabase];
//
//        return sorted;
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSArray * _Nullable)packagesByAuthorName:(NSString *)name email:(NSString *_Nullable)email fullSearch:(BOOL)fullSearch {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *searchResults = [NSMutableArray new];
//
//        sqlite3_stmt *statement = NULL;
//        NSString *columns = fullSearch ? @"*" : @"PACKAGE, NAME, VERSION, REPOID, SECTION, ICON, AUTHOR";
//        NSString *limit = fullSearch ? @";" : @" LIMIT 30;";
//        NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM PACKAGES WHERE AUTHOR = ? OR AUTHOR LIKE \'%%%@%%\'%@", columns, name, limit];
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [name UTF8String], -1, SQLITE_TRANSIENT);
//
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                if (fullSearch) {
//                    const char *packageIDChars = (const char *)sqlite3_column_text(statement, 0);
//                    if (packageIDChars != 0) {
//                        NSString *packageID = [NSString stringWithUTF8String:packageIDChars];
//                        ZBPackage *package = [self topVersionForPackageID:packageID];
//                        if (package) [searchResults addObject:package];
//                    }
//                }
//                else {
//                    ZBProxyPackage *proxyPackage = [[ZBProxyPackage alloc] initWithSQLiteStatement:statement];
//
//                    const char *sectionChars = (const char *)sqlite3_column_text(statement, 4);
//                    const char *iconURLChars = (const char *)sqlite3_column_text(statement, 5);
//
//                    NSString *section = sectionChars != 0 ? [NSString stringWithUTF8String:sectionChars] : NULL;
//                    NSString *iconURLString = iconURLChars != 0 ? [NSString stringWithUTF8String:iconURLChars] : NULL;
//                    NSURL *iconURL = iconURLString ? [NSURL URLWithString:iconURLString] : nil;
//
//                    if (section) proxyPackage.section = section;
//                    if (iconURL) proxyPackage.iconURL = iconURL;
//
//                    [searchResults addObject:proxyPackage];
//                }
//            }
//        }
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//
//        return [self cleanUpDuplicatePackages:searchResults];
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSArray * _Nullable)packagesWithDescription:(NSString *)description fullSearch:(BOOL)fullSearch {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *searchResults = [NSMutableArray new];
//
//        sqlite3_stmt *statement = NULL;
//        NSString *columns = fullSearch ? @"*" : @"PACKAGE, NAME, VERSION, REPOID, SECTION, ICON";
//        NSString *limit = fullSearch ? @";" : @" LIMIT 30;";
//        NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM PACKAGES WHERE DESCRIPTION LIKE \'%%%@%%\'%@", columns, description, limit];
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                if (fullSearch) {
//                    const char *packageIDChars = (const char *)sqlite3_column_text(statement, 0);
//                    if (packageIDChars != 0) {
//                        NSString *packageID = [NSString stringWithUTF8String:packageIDChars];
//                        ZBPackage *package = [self topVersionForPackageID:packageID];
//                        if (package) [searchResults addObject:package];
//                    }
//                }
//                else {
//                    ZBProxyPackage *proxyPackage = [[ZBProxyPackage alloc] initWithSQLiteStatement:statement];
//
//                    const char *sectionChars = (const char *)sqlite3_column_text(statement, 4);
//                    const char *iconURLChars = (const char *)sqlite3_column_text(statement, 5);
//
//                    NSString *section = sectionChars != 0 ? [NSString stringWithUTF8String:sectionChars] : NULL;
//                    NSString *iconURLString = iconURLChars != 0 ? [NSString stringWithUTF8String:iconURLChars] : NULL;
//                    NSURL *iconURL = iconURLString ? [NSURL URLWithString:iconURLString] : nil;
//
//                    if (section) proxyPackage.section = section;
//                    if (iconURL) proxyPackage.iconURL = iconURL;
//
//                    [searchResults addObject:proxyPackage];
//                }
//            }
//        }
//        sqlite3_finalize(statement);
//
//        [self closeDatabase];
//
//        return [self cleanUpDuplicatePackages:searchResults];
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSArray * _Nullable)packagesWithReachableIcon:(int)limit excludeFrom:(NSArray <ZBSource *> *_Nullable)blacklistedSources {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *packages = [NSMutableArray new];
//        NSMutableArray *sourceIDs = [@[[NSNumber numberWithInt:-1], [NSNumber numberWithInt:0]] mutableCopy];
//
//        for (ZBSource *source in blacklistedSources) {
//            [sourceIDs addObject:[NSNumber numberWithInt:[source sourceID]]];
//        }
//        NSString *excludeString = [NSString stringWithFormat:@"(%@)", [sourceIDs componentsJoinedByString:@", "]];
//        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE REPOID NOT IN %@ AND ICON IS NOT NULL ORDER BY RANDOM() LIMIT %d;", excludeString, limit];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//                [packages addObject:package];
//
//            }
//        }
//        [self closeDatabase];
//        return [self cleanUpDuplicatePackages:packages];
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}


- (nullable ZBPackage *)topVersionForPackage:(ZBPackage *)package {
    return [self topVersionForPackage:package inSource:NULL];
}

- (nullable ZBPackage *)topVersionForPackageID:(NSString *)packageIdentifier {
    return [self topVersionForPackageID:packageIdentifier inSource:NULL];
}

- (nullable ZBPackage *)topVersionForPackage:(ZBPackage *)package inSource:(ZBSource *_Nullable)source {
    return [self topVersionForPackageID:package.identifier inSource:source];
}

- (nullable ZBPackage *)topVersionForPackageID:(NSString *)packageIdentifier inSource:(ZBSource *_Nullable)source {
    NSArray *allVersions = [self allVersionsForPackageID:packageIdentifier inSource:source];
    return allVersions.count ? allVersions[0] : nil;
}

- (NSArray <ZBPackage *> * _Nullable)packagesThatDependOn:(ZBPackage *)package {
    return [self packagesThatDependOnPackageIdentifier:[package identifier] removedPackage:package];
}

- (NSArray <ZBPackage *> * _Nullable)packagesThatDependOnPackageIdentifier:(NSString *)packageIdentifier removedPackage:(ZBPackage *)package {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *packages = [NSMutableArray new];
//
//        const char *firstSearchTerm = [[NSString stringWithFormat:@"%%, %@ (%%", packageIdentifier] UTF8String];
//        const char *secondSearchTerm = [[NSString stringWithFormat:@"%%, %@, %%", packageIdentifier] UTF8String];
//        const char *thirdSearchTerm = [[NSString stringWithFormat:@"%@ (%%", packageIdentifier] UTF8String];
//        const char *fourthSearchTerm = [[NSString stringWithFormat:@"%@, %%", packageIdentifier] UTF8String];
//        const char *fifthSearchTerm = [[NSString stringWithFormat:@"%%, %@", packageIdentifier] UTF8String];
//        const char *sixthSearchTerm = [[NSString stringWithFormat:@"%%| %@", packageIdentifier] UTF8String];
//        const char *seventhSearchTerm = [[NSString stringWithFormat:@"%%, %@ |%%", packageIdentifier] UTF8String];
//        const char *eighthSearchTerm = [[NSString stringWithFormat:@"%@ |%%", packageIdentifier] UTF8String];
//
//        const char *query = "SELECT * FROM PACKAGES WHERE (DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS = ?) AND REPOID = 0;";
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, firstSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 2, secondSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 3, thirdSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 4, fourthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 5, fifthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 6, sixthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 7, seventhSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 8, eighthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 9, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
//
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                const char *dependsChars = (const char *)sqlite3_column_text(statement, ZBPackageColumnDepends);
//                NSString *depends = dependsChars != 0 ? [NSString stringWithUTF8String:dependsChars] : NULL; //Depends shouldn't be NULL here but you know just in case because this can be weird
//                NSArray *dependsOn = [depends componentsSeparatedByString:@", "];
//
//                BOOL packageNeedsToBeRemoved = NO;
//                for (NSString *dependsLine in dependsOn) {
//                    NSError *error = NULL;
//                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\b%@\\b", [package identifier]] options:NSRegularExpressionCaseInsensitive error:&error];
//                    if ([regex numberOfMatchesInString:dependsLine options:0 range:NSMakeRange(0, [dependsLine length])] && ![self willDependencyBeSatisfiedAfterQueueOperations:dependsLine]) { //Use regex to search with block words
//                        packageNeedsToBeRemoved = YES;
//                    }
//                }
//
//                if (packageNeedsToBeRemoved) {
//                    ZBPackage *found = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//                    if ([[ZBQueue sharedQueue] locate:found] == ZBQueueTypeClear) {
//                        [found setRemovedBy:package];
//
//                        [packages addObject:found];
//                    }
//                }
//            }
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//
//        for (NSString *provided in [package provides]) { //If the package is removed and there is no other package that provides this dependency, we have to remove those as well
//            if ([provided containsString:packageIdentifier]) continue;
//            if (![[package identifier] isEqualToString:packageIdentifier] && [[package provides] containsObject:provided]) continue;
//            if (![self willDependencyBeSatisfiedAfterQueueOperations:provided]) {
//                [packages addObjectsFromArray:[self packagesThatDependOnPackageIdentifier:provided removedPackage:package]];
//            }
//        }
//
//        return packages.count ? packages : nil;
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

- (NSArray <ZBPackage *> * _Nullable)packagesThatConflictWith:(ZBPackage *)package {
//    if ([self openDatabase] == SQLITE_OK) {
//        NSMutableArray *packages = [NSMutableArray new];
//
//        const char *firstSearchTerm = [[NSString stringWithFormat:@"%%, %@ (%%", [package identifier]] UTF8String];
//        const char *secondSearchTerm = [[NSString stringWithFormat:@"%%, %@, %%", [package identifier]] UTF8String];
//        const char *thirdSearchTerm = [[NSString stringWithFormat:@"%@ (%%", [package identifier]] UTF8String];
//        const char *fourthSearchTerm = [[NSString stringWithFormat:@"%@, %%", [package identifier]] UTF8String];
//        const char *fifthSearchTerm = [[NSString stringWithFormat:@"%%, %@", [package identifier]] UTF8String];
//        const char *sixthSearchTerm = [[NSString stringWithFormat:@"%%| %@", [package identifier]] UTF8String];
//        const char *seventhSearchTerm = [[NSString stringWithFormat:@"%%, %@ |%%", [package identifier]] UTF8String];
//        const char *eighthSearchTerm = [[NSString stringWithFormat:@"%@ |%%", [package identifier]] UTF8String];
//
//        const char *query = "SELECT * FROM PACKAGES WHERE (CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS = ?) AND REPOID = 0;";
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, firstSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 2, secondSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 3, thirdSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 4, fourthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 5, fifthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 6, sixthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 7, seventhSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 8, eighthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 9, [[package identifier] UTF8String], -1, SQLITE_TRANSIENT);
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                ZBPackage *found = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//                [packages addObject:found];
//            }
//        }
//
//        for (ZBPackage *conflictingPackage in [packages copy]) {
//            for (NSString *conflict in [conflictingPackage conflictsWith]) {
//                if (([conflict containsString:@"("] || [conflict containsString:@")"]) && [conflict containsString:[package identifier]]) {
//                    NSArray *versionComparison = [ZBDependencyResolver separateVersionComparison:conflict];
//                    if (![ZBDependencyResolver doesPackage:package satisfyComparison:versionComparison[1] ofVersion:versionComparison[2]]) {
//                        [packages removeObject:conflictingPackage];
//                    }
//                }
//            }
//        }
//
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//        return packages.count ? packages : nil;
//    } else {
//        [self printDatabaseError];
//    }
    return NULL;
}

//- (BOOL)willDependency:(NSString *_Nonnull)dependency beSatisfiedAfterTheRemovalOf:(NSArray <ZBPackage *> *)packages {
//    NSMutableArray *array = [NSMutableArray new];
//    for (ZBPackage *package in packages) {
//        [array addObject:[NSString stringWithFormat:@"\'%@\'", [package identifier]]];
//    }
//    return [self willDependency:dependency beSatisfiedAfterTheRemovalOfPackageIdentifiers:array];
//}

- (BOOL)willDependencyBeSatisfiedAfterQueueOperations:(NSString *_Nonnull)dependency {
//    if ([dependency containsString:@"|"]) {
//        NSArray *components = [dependency componentsSeparatedByString:@"|"];
//        for (NSString *dependency in components) {
//            if ([self willDependencyBeSatisfiedAfterQueueOperations:[dependency stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]]) {
//                return YES;
//            }
//        }
//    }
//    else if ([self openDatabase] == SQLITE_OK) {
//        ZBQueue *queue = [ZBQueue sharedQueue];
//        NSArray *addedPackages =   [queue packagesQueuedForAdddition]; //Packages that are being installed, upgraded, removed, downgraded, etc. (dependencies as well)
//        NSArray *removedPackages = [queue packageIDsQueuedForRemoval]; //Just packageIDs that are queued for removal (conflicts as well)
//
//        NSArray *versionComponents = [ZBDependencyResolver separateVersionComparison:dependency];
//        NSString *packageIdentifier = versionComponents[0];
//        BOOL needsVersionComparison = ![versionComponents[1] isEqualToString:@"<=>"] && ![versionComponents[2] isEqualToString:@"0:0"];
//
//        NSString *excludeString = [self excludeStringFromArray:removedPackages];
//        const char *firstSearchTerm = [[NSString stringWithFormat:@"%%, %@ (%%", packageIdentifier] UTF8String];
//        const char *secondSearchTerm = [[NSString stringWithFormat:@"%%, %@, %%", packageIdentifier] UTF8String];
//        const char *thirdSearchTerm = [[NSString stringWithFormat:@"%@ (%%", packageIdentifier] UTF8String];
//        const char *fourthSearchTerm = [[NSString stringWithFormat:@"%@, %%", packageIdentifier] UTF8String];
//        const char *fifthSearchTerm = [[NSString stringWithFormat:@"%%, %@", packageIdentifier] UTF8String];
//        const char *sixthSearchTerm = [[NSString stringWithFormat:@"%%| %@", packageIdentifier] UTF8String];
//        const char *seventhSearchTerm = [[NSString stringWithFormat:@"%%, %@ |%%", packageIdentifier] UTF8String];
//        const char *eighthSearchTerm = [[NSString stringWithFormat:@"%@ |%%", packageIdentifier] UTF8String];
//
//        NSString *query = [NSString stringWithFormat:@"SELECT VERSION FROM PACKAGES WHERE PACKAGE NOT IN %@ AND REPOID = 0 AND (PACKAGE = ? OR (PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ?)) LIMIT 1;", excludeString];
//
//        BOOL found = NO;
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 2, firstSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 3, secondSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 4, thirdSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 5, fourthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 6, fifthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 7, sixthSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 8, seventhSearchTerm, -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(statement, 9, eighthSearchTerm, -1, SQLITE_TRANSIENT);
//
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                if (needsVersionComparison) {
//                    const char* foundVersion = (const char*)sqlite3_column_text(statement, 0);
//
//                    if (foundVersion != 0) {
//                        if ([ZBDependencyResolver doesVersion:[NSString stringWithUTF8String:foundVersion] satisfyComparison:versionComponents[1] ofVersion:versionComponents[2]]) {
//                            found = YES;
//                            break;
//                        }
//                    }
//                }
//                else {
//                    found = YES;
//                    break;
//                }
//            }
//
//            if (!found) { //Search the array of packages that are queued for installation to see if one of them satisfies the dependency
//                for (NSDictionary *package in addedPackages) {
//                    if ([[package objectForKey:@"identifier"] isEqualToString:packageIdentifier]) {
//                        // TODO: Condition check here is useless
////                        if (needsVersionComparison && [ZBDependencyResolver doesVersion:[package objectForKey:@"version"] satisfyComparison:versionComponents[1] ofVersion:versionComponents[2]]) {
////                            return YES;
////                        }
//                        return YES;
//                    }
//                }
//                return NO;
//            }
//
//            sqlite3_finalize(statement);
//            [self closeDatabase];
//            return found;
//        } else {
//            [self printDatabaseError];
//        }
//        [self closeDatabase];
//    }
//    else {
//        [self printDatabaseError];
//    }
    return NO;
}

#pragma mark - Helper methods

- (NSArray *)cleanUpDuplicatePackages:(NSArray <ZBPackage *> *)packageList {
//    NSMutableDictionary *packageVersionDict = [[NSMutableDictionary alloc] init];
//    NSMutableArray *results = [NSMutableArray array];
//
//    for (ZBPackage *package in packageList) {
//        ZBPackage *packageFromDict = packageVersionDict[package.identifier];
//        if (packageFromDict == NULL) {
//            packageVersionDict[package.identifier] = package;
//            [results addObject:package];
//            continue;
//        }
//
//        if ([package sameAs:packageFromDict]) {
//            NSString *packageDictVersion = [packageFromDict version];
//            NSString *packageVersion = package.version;
//            int result = compare([packageVersion UTF8String], [packageDictVersion UTF8String]);
//
//            if (result > 0) {
//                NSUInteger index = [results indexOfObject:packageFromDict];
//                packageVersionDict[package.identifier] = package;
//                [results replaceObjectAtIndex:index withObject:package];
//            }
//        }
//    }
//
//    return results;
    return NULL;
}

- (ZBPackage * _Nullable)localVersionForPackage:(ZBPackage *)package {
    if ([[package source] sourceID] == 0) return package;
    if (![package isInstalled:NO]) return NULL;
    
    ZBPackage *localPackage = NULL;
//    if ([self openDatabase] == SQLITE_OK) {
//        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE = '%@' AND REPOID = 0", [package identifier]];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                localPackage = [[ZBPackage alloc] initWithSQLiteStatement:statement];
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//    } else {
//        [self printDatabaseError];
//    }
//
    return localPackage;
}

- (NSString * _Nullable)installedVersionForPackage:(ZBPackage *)package {
    NSString *version = NULL;
//    if ([self openDatabase] == SQLITE_OK) {
//        NSString *query = [NSString stringWithFormat:@"SELECT VERSION FROM PACKAGES WHERE PACKAGE = '%@' AND REPOID = 0", [package identifier]];
//
//        sqlite3_stmt *statement = NULL;
//        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                const char *versionChars = (const char *)sqlite3_column_text(statement, 0);
//                if (versionChars != 0) {
//                    version = [NSString stringWithUTF8String:versionChars];
//                }
//                break;
//            }
//        } else {
//            [self printDatabaseError];
//        }
//        sqlite3_finalize(statement);
//        [self closeDatabase];
//    } else {
//        [self printDatabaseError];
//    }
//
    return version;
}

- (NSString * _Nullable)excludeStringFromArray:(NSArray *)array {
//    if ([array count]) {
//        NSMutableString *result = [@"(" mutableCopy];
//        [result appendString:[NSString stringWithFormat:@"\'%@\'", array[0]]];
//        for (int i = 1; i < array.count; ++i) {
//            [result appendFormat:@", \'%@\'", array[i]];
//        }
//        [result appendString:@")"];
//
//        return result;
//    }
    return NULL;
}

#pragma mark - Statement Preparation

- (NSString *)statementStringForStatementType:(ZBDatabaseStatementType)statement {
    switch (statement) {
        case ZBDatabaseStatementTypePackagesFromSource:
            return @"SELECT authorName, description, identifier, lastSeen, name, version, section, uuid FROM " PACKAGES_TABLE_NAME " WHERE source = ?;";
        case ZBDatabaseStatementTypePackagesFromSourceAndSection:
            return @"SELECT authorName, description, identifier, lastSeen, name, version, section, uuid FROM " PACKAGES_TABLE_NAME " WHERE source = ? AND section = ?;";
        case ZBDatabaseStatementTypeUUIDsFromSource:
            return @"SELECT uuid FROM " PACKAGES_TABLE_NAME " WHERE source = ?";
        case ZBDatabaseStatementTypePackageWithUUID:
            return @"SELECT * FROM " PACKAGES_TABLE_NAME " WHERE uuid = ?;";
        case ZBDatabaseStatementTypeRemovePackageWithUUID:
            return @"DELETE FROM " PACKAGES_TABLE_NAME " WHERE uuid = ?";
        case ZBDatabaseStatementTypeInsertPackage:
            return @"INSERT INTO " PACKAGES_TABLE_NAME "(authorName, description, identifier, lastSeen, name, version, section, uuid, authorEmail, conflicts, depends, depictionURL, downloadSize, essential, filename, homepageURL, iconURL, installedSize, maintainerEmail, maintainerName, priority, provides, replaces, role, sha256, tag, source) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
        case ZBDatabaseStatementTypeSources:
            return @"SELECT * FROM " SOURCES_TABLE_NAME ";";
        case ZBDatabaseStatementTypeInsertSource:
            return @"INSERT INTO " SOURCES_TABLE_NAME "(architectures, archiveType, codename, components, distribution, label, origin, remote, sourceDescription, suite, url, uuid, version) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
        case ZBDatabaseStatementTypeSectionReadout:
            return @"SELECT section, COUNT(DISTINCT identifier) from " PACKAGES_TABLE_NAME " WHERE source = ? GROUP BY section ORDER BY section";
        case ZBDatabaseStatementTypePackagesInSourceCount:
            return @"SELECT COUNT(DISTINCT identifier) from " PACKAGES_TABLE_NAME " WHERE source = ?;";
        default:
            return nil;
    }
}

- (sqlite3_stmt *)preparedStatementOfType:(ZBDatabaseStatementType)statementType {
    sqlite3_stmt *statement = preparedStatements[statementType];
    sqlite3_reset(statement);
    return statement;
}

- (int)initializePreparedStatements {
    int result = SQLITE_OK;

    preparedStatements = (sqlite3_stmt **) malloc(sizeof(sqlite3_stmt *) * ZBDatabaseStatementTypeCount);
    if (!preparedStatements) {
        ZBLog(@"[Zebra] Failed to allocate buffer for prepared statements");
        result = SQLITE_NOMEM;
    }

    if (result == SQLITE_OK) {
        for (unsigned int i = 0; i < ZBDatabaseStatementTypeCount; i++) {
            ZBDatabaseStatementType statementType = (ZBDatabaseStatementType)i;
            const char *statement = [[self statementStringForStatementType:statementType] UTF8String];
            NSLog(@"Statement: %s", statement);
            if (sqlite3_prepare(database, statement, -1, &preparedStatements[statementType], NULL) != SQLITE_OK) {
                ZBLog(@"[Zebra] Failed to prepare sqlite statement %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
                free(preparedStatements);
                preparedStatements = NULL;
                break;
            }
        }
    }

    return result;
}

#pragma mark - Managing Transactions

- (int)beginTransaction {
    int result = sqlite3_exec(database, "BEGIN EXCLUSIVE TRANSACTION;", NULL, NULL, NULL);
    if (result != SQLITE_OK) {
        ZBLog(@"[Zebra] Failed to begin transaction with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
    }
    return result;
}

- (int)endTransaction {
    int result = sqlite3_exec(database, "COMMIT;", NULL, NULL, NULL);
    if (result != SQLITE_OK) {
        ZBLog(@"[Zebra] Failed to commit transaction with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
    }
    return result;
}

#pragma mark - Package Retrieval

- (NSArray <ZBBasePackage *> *)packagesFromSource:(ZBSource *)source {
    return [self packagesFromSource:source inSection:NULL];
}

- (NSArray <ZBBasePackage *> *)packagesFromSource:(ZBSource *)source inSection:(NSString *)section {
    sqlite3_stmt *statement = [self preparedStatementOfType:section ? ZBDatabaseStatementTypePackagesFromSourceAndSection : ZBDatabaseStatementTypePackagesFromSource];
    int result = sqlite3_bind_text(statement, 1, source.uuid.UTF8String, -1, SQLITE_TRANSIENT);
    if (section) result = sqlite3_bind_text(statement, 2, section.UTF8String, -1, SQLITE_TRANSIENT);
    if (result == SQLITE_OK) {
        result = [self beginTransaction];
    }
    
    NSMutableArray *packages = [NSMutableArray new];
    if (result == SQLITE_OK) {
        do {
            result = sqlite3_step(statement);
            if (result == SQLITE_ROW) {
                ZBBasePackage *package = [[ZBBasePackage alloc] initFromSQLiteStatement:statement];
                [packages addObject:package];
            }
        } while (result == SQLITE_ROW);
        
        if (result != SQLITE_DONE) {
            ZBLog(@"[Zebra] Failed to query packages from %@ with error %d (%s, %d)", source.uuid, result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
        }
    }
    
    [self endTransaction];
    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
    
    return packages;
}

- (NSSet *)uniqueIdentifiersForPackagesFromSource:(ZBSource *)source {
    sqlite3_stmt *statement = [self preparedStatementOfType:ZBDatabaseStatementTypeUUIDsFromSource];
    int result = sqlite3_bind_text(statement, 1, [source.uuid UTF8String], -1, SQLITE_TRANSIENT);
    if (result == SQLITE_OK) {
        result = [self beginTransaction];
    }
    
    NSMutableSet *uuids = [NSMutableSet new];
    if (result == SQLITE_OK) {
        do {
            result = sqlite3_step(statement);
            if (result == SQLITE_ROW) {
                const char *uuid = (const char *)sqlite3_column_text(statement, 0);
                if (uuid) {
                    [uuids addObject:[NSString stringWithUTF8String:uuid]];
                }
            }
        } while (result == SQLITE_ROW);
        
        if (result != SQLITE_DONE) {
            ZBLog(@"[Zebra] Failed to query package uuids from %@ with error %d (%s, %d)", source.uuid, result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
        }
    }
    
    [self endTransaction];
    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
    
    return uuids;
}

- (ZBPackage *)packageWithUniqueIdentifier:(NSString *)uuid {
    sqlite3_stmt *statement = [self preparedStatementOfType:ZBDatabaseStatementTypePackageWithUUID];
    int result = sqlite3_bind_text(statement, 1, [uuid UTF8String], -1, SQLITE_TRANSIENT);
    if (result == SQLITE_OK) {
        result = [self beginTransaction];
    }
    
    ZBPackage *package;
    if (result == SQLITE_OK) {
        result = sqlite3_step(statement);
        if (result == SQLITE_ROW) {
            package = [[ZBPackage alloc] initFromSQLiteStatement:statement];
        }
        
        if (result != SQLITE_OK && result != SQLITE_ROW) {
            ZBLog(@"[Zebra] Failed to query package with uuid with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
        }
    }
    
    [self endTransaction];
    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
    
    return package;
}

#pragma mark - Source Retrieval

- (NSSet <ZBSource *> *)sources {
    sqlite3_stmt *statement = [self preparedStatementOfType:ZBDatabaseStatementTypeSources];
    int result = [self beginTransaction];
    
    NSMutableSet *sources = [NSMutableSet new];
    if (result == SQLITE_OK) {
        do {
            result = sqlite3_step(statement);
            if (result == SQLITE_ROW) {
                ZBSource *source = [[ZBSource alloc] initWithSQLiteStatement:statement];
                if (source) [sources addObject:source];
            }
        } while (result == SQLITE_ROW);
        
        if (result != SQLITE_DONE) {
            ZBLog(@"[Zebra] Failed to query sources with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
        }
    }
    
    [self endTransaction];
    sqlite3_reset(statement);
    
    return sources;
}

- (NSUInteger)numberOfPackagesInSource:(ZBSource *)source {
    sqlite3_stmt *statement = [self preparedStatementOfType:ZBDatabaseStatementTypePackagesInSourceCount];
    NSUInteger packageCount = 0;
    
    int result = sqlite3_bind_text(statement, 1, source.uuid.UTF8String, -1, SQLITE_TRANSIENT);
    if (result == SQLITE_OK) {
        result = sqlite3_step(statement);
        if (result == SQLITE_ROW) {
            packageCount = sqlite3_column_int(statement, 0);
        }
    }
    
    if (result != SQLITE_OK && result != SQLITE_ROW) {
        ZBLog(@"[Zebra] Failed to obtain package count from source with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
    }
    
    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
    return packageCount;
}

- (NSDictionary *)sectionReadoutForSource:(ZBSource *)source {
    sqlite3_stmt *statement = [self preparedStatementOfType:ZBDatabaseStatementTypeSectionReadout];
    int result = [self beginTransaction];
    
    result = sqlite3_bind_text(statement, 1, source.uuid.UTF8String, -1, SQLITE_TRANSIENT);
    
    NSMutableDictionary *sectionReadout = [NSMutableDictionary new];
    if (result == SQLITE_OK) {
        do {
            result = sqlite3_step(statement);
            if (result == SQLITE_ROW) {
                const char *section = (const char *)sqlite3_column_text(statement, 0);
                if (section) {
                    int packageCount = sqlite3_column_int(statement, 1);
                    sectionReadout[[NSString stringWithUTF8String:section]] = @(packageCount);
                }
            }
        } while (result == SQLITE_ROW);
        
        if (result != SQLITE_DONE) {
            ZBLog(@"[Zebra] Failed to query section readout with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
        }
        
        sectionReadout[@"ALL_PACKAGES"] = @([self numberOfPackagesInSource:source]);
    }

    [self endTransaction];
    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
    
    return sectionReadout;
}

#pragma mark - Package Management

- (void)insertPackage:(char **)package {
    sqlite3_stmt *statement = [self preparedStatementOfType:ZBDatabaseStatementTypeInsertPackage];
    
    sqlite3_bind_text(statement, ZBPackageColumnIdentifier + 1, package[ZBPackageColumnIdentifier], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnName + 1, package[ZBPackageColumnName], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnVersion + 1, package[ZBPackageColumnVersion], -1, SQLITE_TRANSIENT);
    
    char *author = package[ZBPackageColumnAuthorName];
    char *emailBegin = strchr(author, '<');
    char *emailEnd = strchr(author, '>');
    if (emailBegin && emailEnd) {
        char *email = (char *)malloc(emailEnd - emailBegin);
        memcpy(email, emailBegin + 1, emailEnd - emailBegin - 1);
        email[emailEnd - emailBegin - 1] = 0;
        
        if (*emailBegin - 1 == ' ') {
            emailBegin--;
        }
        *emailBegin = 0;
        
        unsigned long authorLength = strlen(author);
        if (author[authorLength - 1] == ' ') {
            author[authorLength - 1] = 0;
        }
        
        sqlite3_bind_text(statement, ZBPackageColumnAuthorName + 1, author, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, ZBPackageColumnAuthorEmail + 1, email, -1, SQLITE_TRANSIENT);
        free(email);
    } else {
        sqlite3_bind_text(statement, ZBPackageColumnAuthorName + 1, author, -1, SQLITE_TRANSIENT);
        sqlite3_bind_null(statement, ZBPackageColumnAuthorEmail + 1);
    }
    
    sqlite3_bind_text(statement, ZBPackageColumnConflicts + 1, package[ZBPackageColumnConflicts], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnDepends + 1, package[ZBPackageColumnDepends], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnDepictionURL + 1, package[ZBPackageColumnDepictionURL], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(statement, ZBPackageColumnDownloadSize + 1, atoi(package[ZBPackageColumnDownloadSize]));
//    package.essential = packageDictionary[@"Essential"];
    sqlite3_bind_text(statement, ZBPackageColumnFilename + 1, package[ZBPackageColumnFilename], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnHomepageURL + 1, package[ZBPackageColumnHomepageURL], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(statement, ZBPackageColumnInstalledSize + 1, atoi(package[ZBPackageColumnInstalledSize]));
    
    char *maintainer = package[ZBPackageColumnMaintainerName];
    emailBegin = strchr(maintainer, '<');
    emailEnd = strchr(author, '>');
    if (emailBegin && emailEnd) {
        char *email = (char *)malloc(emailEnd - emailBegin);
        memcpy(email, emailBegin + 1, emailEnd - emailBegin - 1);
        email[emailEnd - emailBegin] = '\0';
        
        if (*emailBegin - 1 == ' ') {
            emailBegin--;
        }
        *emailBegin = 0;
        
        unsigned long maintainerLength = strlen(maintainer);
        if (author[maintainerLength - 1] == ' ') {
            author[maintainerLength - 1] = 0;
        }
        
        sqlite3_bind_text(statement, ZBPackageColumnAuthorName + 1, maintainer, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, ZBPackageColumnAuthorEmail + 1, email, -1, SQLITE_TRANSIENT);
        free(email);
    } else {
        sqlite3_bind_text(statement, ZBPackageColumnAuthorName + 1, maintainer, -1, SQLITE_TRANSIENT);
        sqlite3_bind_null(statement, ZBPackageColumnAuthorEmail + 1);
    }
    
    sqlite3_bind_text(statement, ZBPackageColumnDescription + 1, package[ZBPackageColumnDescription], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnPriority + 1, package[ZBPackageColumnPriority], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnProvides + 1, package[ZBPackageColumnProvides], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnReplaces + 1, package[ZBPackageColumnReplaces], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnSection + 1, package[ZBPackageColumnSection], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnSHA256 + 1, package[ZBPackageColumnSHA256], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnTag + 1, package[ZBPackageColumnTag], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnVersion + 1, package[ZBPackageColumnVersion], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnSource + 1, package[ZBPackageColumnSource], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBPackageColumnUUID + 1, package[ZBPackageColumnUUID], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(statement, ZBPackageColumnLastSeen + 1, *(int *)package[ZBPackageColumnLastSeen]);
    
    int result = sqlite3_step(statement);
    if (result != SQLITE_DONE) {
        ZBLog(@"[Zebra] Failed to insert package into database with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
    }
    
    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
}

- (void)deletePackagesWithUniqueIdentifiers:(NSSet *)uniqueIdentifiers {
    sqlite3_stmt *statement = [self preparedStatementOfType:ZBDatabaseStatementTypeRemovePackageWithUUID];
    int result = [self beginTransaction];
    for (NSString *uuid in uniqueIdentifiers) {
        result = sqlite3_bind_text(statement, 1, [uuid UTF8String], -1, SQLITE_TRANSIENT);
        if (result == SQLITE_OK) {
            result = sqlite3_step(statement);
            
            if (result != SQLITE_DONE) {
                ZBLog(@"[Zebra] Failed to delete package with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
            }
        }
        sqlite3_clear_bindings(statement);
        sqlite3_reset(statement);
    }
    
    [self endTransaction];
    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
}

#pragma mark - Source Management

- (void)insertSource:(char * _Nonnull * _Nonnull)source {
    sqlite3_stmt *statement = [self preparedStatementOfType:ZBDatabaseStatementTypeInsertSource];
    
    sqlite3_bind_text(statement, ZBSourceColumnArchitectures + 1, source[ZBSourceColumnArchiveType], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBSourceColumnArchiveType + 1, source[ZBSourceColumnArchiveType], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBSourceColumnCodename + 1, source[ZBSourceColumnCodename], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBSourceColumnComponents + 1, source[ZBSourceColumnComponents], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBSourceColumnDistribution + 1, source[ZBSourceColumnDistribution], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBSourceColumnLabel + 1, source[ZBSourceColumnLabel], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBSourceColumnOrigin + 1, source[ZBSourceColumnOrigin], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(statement, ZBSourceColumnRemote + 1, *(int *)source[ZBSourceColumnRemote]);
    sqlite3_bind_text(statement, ZBSourceColumnDescription + 1, source[ZBSourceColumnDescription], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBSourceColumnSuite + 1, source[ZBSourceColumnSuite], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBSourceColumnURL + 1, source[ZBSourceColumnURL], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBSourceColumnUUID + 1, source[ZBSourceColumnUUID], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, ZBSourceColumnVersion + 1, source[ZBSourceColumnVersion], -1, SQLITE_TRANSIENT);
    
    int result = sqlite3_step(statement);
    if (result != SQLITE_DONE) {
        ZBLog(@"[Zebra] Failed to insert source into database with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
    }
    
    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
}

@end
