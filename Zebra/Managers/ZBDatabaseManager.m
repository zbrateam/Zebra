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
#import "utils.h"

typedef NS_ENUM(NSUInteger, ZBDatabaseStatementType) {
    ZBDatabaseStatementTypePackagesFromSource,
    ZBDatabaseStatementTypePackagesFromSourceAndSection,
    ZBDatabaseStatementTypeUUIDsFromSource,
    ZBDatabaseStatementTypePackageWithUUID,
    ZBDatabaseStatementTypeIsPackageInstalled,
    ZBDatabaseStatementTypeIsPackageInstalledWithVersion,
    ZBDatabaseStatementTypeInstalledInstanceOfPackage,
    ZBDatabaseStatementTypeInstalledVersionOfPackage,
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
        result = sqlite3_create_function(database, "maxversion", 1, SQLITE_UTF8, NULL, NULL, maxVersionStep, maxVersionFinal);
        if (result != SQLITE_OK) {
            ZBLog(@"[Zebra] Failed to create aggregate function at %s", databasePath);
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

- (ZBSource *)sourceFromUniqueIdentifier:(NSString *)uuid {
    return nil;
}

- (void)updateURIForSource:(ZBSource *)source {
    
}

- (void)deleteSource:(ZBSource *)source {

}

- (NSArray <ZBPackage *> *)packagesWithIgnoredUpdates {
    return nil;
}

- (NSMutableArray <ZBPackage *> *)packagesWithUpdates {
    return nil;
}

- (NSArray *)searchForPackageName:(NSString *)name {
    return NULL;
}

- (NSArray <NSArray <NSString *> *> *)searchForAuthorByName:(NSString *)authorName {
    return NULL;
}

- (NSArray <NSString *> *)searchForAuthorByEmail:(NSString *)authorEmail fullSearch:(BOOL)fullSearch {
    return NULL;
}

- (NSArray <ZBPackage *> *)packagesFromIdentifiers:(NSArray <NSString *> *)requestedPackages {
    return NULL;
}

- (BOOL)isPackageAvailable:(ZBPackage *)package versionStrict:(BOOL)strict {
    return NO;
}

- (BOOL)areUpdatesIgnoredForPackage:(ZBPackage *)package {
    return NO;
}

- (void)setUpdatesIgnored:(BOOL)ignore forPackage:(ZBPackage *)package {
    
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

#pragma mark - Statement Preparation

- (NSString *)statementStringForStatementType:(ZBDatabaseStatementType)statement {
    switch (statement) {
        case ZBDatabaseStatementTypePackagesFromSource:
            return @"SELECT p.authorName, p.description, p.identifier, p.lastSeen, p.name, p.version, p.section, p.uuid FROM (SELECT identifier, maxversion(version) AS max_version FROM " PACKAGES_TABLE_NAME " WHERE source = ? GROUP BY identifier) as v INNER JOIN " PACKAGES_TABLE_NAME " AS p ON p.identifier = v.identifier AND p.version = v.max_version;";
        case ZBDatabaseStatementTypePackagesFromSourceAndSection:
            return @"SELECT p.authorName, p.description, p.identifier, p.lastSeen, p.name, p.version, p.section, p.uuid FROM (SELECT identifier, maxversion(version) AS max_version FROM " PACKAGES_TABLE_NAME " WHERE source = ? AND section = ? GROUP BY identifier) as v INNER JOIN " PACKAGES_TABLE_NAME " AS p ON p.identifier = v.identifier AND p.version = v.max_version;";
        case ZBDatabaseStatementTypeUUIDsFromSource:
            return @"SELECT uuid FROM " PACKAGES_TABLE_NAME " WHERE source = ?";
        case ZBDatabaseStatementTypePackageWithUUID:
            return @"SELECT * FROM " PACKAGES_TABLE_NAME " WHERE uuid = ?;";
        case ZBDatabaseStatementTypeIsPackageInstalled:
            return @"SELECT 1 FROM " PACKAGES_TABLE_NAME " WHERE identifier = ? AND source = \'_var_lib_dpkg_status\' LIMIT 1;";
        case ZBDatabaseStatementTypeIsPackageInstalledWithVersion:
            return @"SELECT 1 FROM " PACKAGES_TABLE_NAME " WHERE identifier = ? AND version = ? AND source = \'_var_lib_dpkg_status\' LIMIT 1;";
        case ZBDatabaseStatementTypeInstalledInstanceOfPackage:
            return @"SELECT authorName, description, identifier, lastSeeen, name, version, section, uuid FROM " PACKAGES_TABLE_NAME " WHERE identifier = ? and source = \'_var_lib_dpkg_status\';";
        case ZBDatabaseStatementTypeInstalledVersionOfPackage:
            return @"SELECT version FROM " PACKAGES_TABLE_NAME " WHERE identifier = ? AND source = \'_var_lib_dpkg_status\';";
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
    int result = sqlite3_bind_text(statement, 1, uuid.UTF8String, -1, SQLITE_TRANSIENT);
    
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
    
    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
    
    return package;
}

- (BOOL)isPackageInstalled:(ZBPackage *)package {
    return [self isPackageInstalled:package checkVersion:NO];
}

- (BOOL)isPackageInstalled:(ZBPackage *)package checkVersion:(BOOL)checkVersion {
    sqlite3_stmt *statement = [self preparedStatementOfType:checkVersion ? ZBDatabaseStatementTypeIsPackageInstalled : ZBDatabaseStatementTypeIsPackageInstalledWithVersion];
    int result = sqlite3_bind_text(statement, 1, package.identifier.UTF8String, -1, SQLITE_TRANSIENT);
    if (checkVersion) result = sqlite3_bind_text(statement, 1, package.version.UTF8String, -1, SQLITE_TRANSIENT);
    
    BOOL installed = NO;
    if (result == SQLITE_OK) {
        result = sqlite3_step(statement);
        if (result == SQLITE_ROW) {
            installed = YES;
        }
        
        if (result != SQLITE_DONE && result != SQLITE_OK && result != SQLITE_ROW) {
            ZBLog(@"[Zebra] Failed to query if package is installed with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
        }
    }
    
    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
    
    return installed;
}

- (ZBBasePackage *)installedInstanceOfPackage:(ZBPackage *)package {
    sqlite3_stmt *statement = [self preparedStatementOfType:ZBDatabaseStatementTypeInstalledInstanceOfPackage];
    int result = sqlite3_bind_text(statement, 1, package.identifier.UTF8String, -1, SQLITE_TRANSIENT);
    
    ZBBasePackage *installedInstance = NULL;
    if (result == SQLITE_OK) {
        result = sqlite3_step(statement);
        if (result == SQLITE_ROW) {
            installedInstance = [[ZBBasePackage alloc] initFromSQLiteStatement:statement];
        }
        
        if (result != SQLITE_DONE && result != SQLITE_OK && result != SQLITE_ROW) {
            ZBLog(@"[Zebra] Failed to get installed instance of package with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
        }
    }

    return installedInstance;
}

- (NSString *)installedVersionOfPackage:(ZBPackage *)package {
    sqlite3_stmt *statement = [self preparedStatementOfType:ZBDatabaseStatementTypeInstalledVersionOfPackage];
    int result = sqlite3_bind_text(statement, 1, package.identifier.UTF8String, -1, SQLITE_TRANSIENT);
    
    NSString *installedVersion = NULL;
    if (result == SQLITE_OK) {
        result = sqlite3_step(statement);
        if (result == SQLITE_ROW) {
            const char *version = (const char *)sqlite3_column_text(statement, 0);
            if (version) {
                installedVersion = [NSString stringWithUTF8String:version];
            }
        }
        
        if (result != SQLITE_DONE && result != SQLITE_OK && result != SQLITE_ROW) {
            ZBLog(@"[Zebra] Failed to get installed version of package with error %d (%s, %d)", result, sqlite3_errmsg(database), sqlite3_extended_errcode(database));
        }
    }

    return installedVersion;
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
        
        if (*(emailBegin - 1) == ' ') {
            emailBegin--;
        }
        *emailBegin = 0;
        
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
    sqlite3_bind_text(statement, ZBPackageColumnIconURL + 1, package[ZBPackageColumnIconURL], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(statement, ZBPackageColumnInstalledSize + 1, atoi(package[ZBPackageColumnInstalledSize]));
    
    char *maintainer = package[ZBPackageColumnMaintainerName];
    emailBegin = strchr(maintainer, '<');
    emailEnd = strchr(maintainer, '>');
    if (emailBegin && emailEnd) {
        char *email = (char *)malloc(emailEnd - emailBegin);
        memcpy(email, emailBegin + 1, emailEnd - emailBegin - 1);
        email[emailEnd - emailBegin - 1] = 0;
        
        if (*(emailBegin - 1) == ' ') {
            emailBegin--;
        }
        *emailBegin = 0;
        
        sqlite3_bind_text(statement, ZBPackageColumnMaintainerName + 1, maintainer, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, ZBPackageColumnMaintainerEmail + 1, email, -1, SQLITE_TRANSIENT);
        free(email);
    } else {
        sqlite3_bind_text(statement, ZBPackageColumnMaintainerName + 1, maintainer, -1, SQLITE_TRANSIENT);
        sqlite3_bind_null(statement, ZBPackageColumnMaintainerEmail + 1);
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
