//
//  ZBDatabaseManager.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBDatabaseManager.h"
#import <Parsel/parsel.h>
#import <ZBAppDelegate.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Parsel/dpkgver.h>
#import <Hyena/Hyena.h>

@implementation ZBDatabaseManager

- (id)init {
    self = [super init];
    
    if (self) {
        databasePath = [ZBAppDelegate databaseLocation];
    }
    
    return self;
}

- (void)updateDatabaseUsingCaching:(BOOL)useCaching singleRepo:(ZBRepo * _Nullable)repo completion:(void (^)(BOOL success, NSError *error))completion {
    [self postStatusUpdate:@"Updating Repositories\n" atLevel:1];
    
    Hyena *predator;
    if (repo != NULL) {
        predator = [[Hyena alloc] initWithSource:repo];
    }
    else {
        predator = [[Hyena alloc] initWithSourceListPath:[ZBAppDelegate sourceListLocation]];
    }

    [predator downloadReposWithCompletion:^(NSDictionary * _Nonnull fileUpdates, BOOL success) {
        [self postStatusUpdate:@"Download Complete\n" atLevel:1];
        
        NSArray *releaseFiles = fileUpdates[@"release"];
        NSArray *packageFiles = fileUpdates[@"packages"];
        
        [self postStatusUpdate:[NSString stringWithFormat:@"%d Release files need to be updated\n", (int)[releaseFiles count]] atLevel:1];
        [self postStatusUpdate:[NSString stringWithFormat:@"%d Package files need to be updated\n", (int)[packageFiles count]] atLevel:1];
        
        sqlite3 *database;
        sqlite3_open([self->databasePath UTF8String], &database);
        
        for (NSString *releasePath in releaseFiles) {
            NSString *baseFileName = [[releasePath lastPathComponent] stringByReplacingOccurrencesOfString:@"_Release" withString:@""];
            
            int repoID = [self repoIDFromBaseFileName:baseFileName inDatabase:database];
            if (repoID == -1) { //Repo does not exist in database, create it.
                repoID = [self nextRepoIDInDatabase:database];
                importRepoToDatabase([[ZBAppDelegate sourceListLocation] UTF8String], [releasePath UTF8String], database, repoID);
            }
            else {
                updateRepoInDatabase([[ZBAppDelegate sourceListLocation] UTF8String], [releasePath UTF8String], database, repoID);
            }
        }
        
        for (NSString *packagesPath in packageFiles) {
            NSString *baseFileName = [[packagesPath lastPathComponent] stringByReplacingOccurrencesOfString:@"_Packages" withString:@""];
            baseFileName = [baseFileName stringByReplacingOccurrencesOfString:@"_main_binary-iphoneos-arm" withString:@""];
            
            [self postStatusUpdate:[NSString stringWithFormat:@"Parsing %@\n", baseFileName] atLevel:0];
            
            int repoID = [self repoIDFromBaseFileName:baseFileName inDatabase:database];
            if (repoID == -1) { //Repo does not exist in database, create it (this should never happen).
                NSLog(@"[Zebra] Repo for BFN %@ does not exist in the database.", baseFileName);
                repoID = [self nextRepoIDInDatabase:database];
                updatePackagesInDatabase([packagesPath UTF8String], database, repoID);
            }
            else {
                updatePackagesInDatabase([packagesPath UTF8String], database, repoID);
            }
        }
        
        [self postStatusUpdate:@"Done!\n" atLevel:1];
        sqlite3_close(database);
        
        [self importLocalPackages:^(BOOL success) {
            completion(true, NULL);
        }];
        
    } ignoreCache:!useCaching];
}

- (void)importLocalPackages:(void (^)(BOOL success))completion {
    NSString *installedPath;
    if ([ZBAppDelegate needsSimulation]) { //If the target is a simlator, load a demo list of installed packages
        installedPath = [[NSBundle mainBundle] pathForResource:@"Installed" ofType:@"pack"];
    }
    else { //Otherwise, load the actual file
        installedPath = @"/var/lib/dpkg/status";
    }
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    char *sql = "DELETE FROM PACKAGES WHERE REPOID = 0";
    sqlite3_exec(database, sql, NULL, 0, NULL);
    char *negativeOne = "DELETE FROM PACKAGES WHERE REPOID = -1";
    sqlite3_exec(database, negativeOne, NULL, 0, NULL);
    importPackagesToDatabase([installedPath UTF8String], database, 0);
    sqlite3_close(database);
    completion(true);
}

- (void)postStatusUpdate:(NSString *)update atLevel:(int)level {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @(level), @"message": update}];
}

- (int)repoIDFromBaseFileName:(NSString *)bfn inDatabase:(sqlite3 *)database {
    NSString *query = [NSString stringWithFormat:@"SELECT REPOID FROM REPOS WHERE BASEFILENAME = \'%@\'", bfn];
    
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    int repoID = -1;
    while (sqlite3_step(statement) == SQLITE_ROW) {
        repoID = sqlite3_column_int(statement, 0);
    }
    sqlite3_finalize(statement);
    
    return repoID;
}

- (int)nextRepoIDInDatabase:(sqlite3 *)database {
    NSString *query = @"SELECT REPOID FROM REPOS ORDER BY REPOID DESC LIMIT 1";
    
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    int repoID = 0;
    while (sqlite3_step(statement) == SQLITE_ROW) {
        repoID = sqlite3_column_int(statement, 0);
    }
    
    sqlite3_finalize(statement);
    
    return repoID + 1;
}

- (int)numberOfPackagesInRepo:(ZBRepo *)repo {
    int numberOfPackages = 0;
    
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(DISTINCT PACKAGE) FROM PACKAGES WHERE REPOID = %d", [repo repoID]];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        numberOfPackages = sqlite3_column_int(statement, 0);
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
    return numberOfPackages;
}

- (NSArray <ZBRepo *> *)sources {
    NSMutableArray *sources = [NSMutableArray new];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *query = @"SELECT * FROM REPOS ORDER BY ORIGIN COLLATE NOCASE ASC";
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        ZBRepo *source = [[ZBRepo alloc] initWithSQLiteStatement:statement];
        
        [sources addObject:source];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
    return (NSArray*)sources;
}

- (NSArray <ZBPackage *> *)packagesFromRepo:(ZBRepo *)repo inSection:(NSString * _Nullable)section numberOfPackages:(int)limit startingAt:(int)start {
    NSMutableArray *packages = [NSMutableArray new];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *query;
    
    if (section == NULL) {
        query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE REPOID = %d ORDER BY NAME COLLATE NOCASE ASC LIMIT %d OFFSET %d", [repo repoID], limit, start];
    }
    else {
        query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE SECTION = '\%@\' AND REPOID = %d ORDER BY NAME COLLATE NOCASE ASC LIMIT %d OFFSET %d", section, [repo repoID], limit, start];
    }
    
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
        
        [packages addObject:package];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
    return (NSArray *)[self cleanUpDuplicatePackages:packages];
}

- (NSArray <ZBPackage *> *)installedPackages {
    NSMutableArray *installedPackages = [NSMutableArray new];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *query = @"SELECT * FROM PACKAGES WHERE REPOID = 0 ORDER BY NAME COLLATE NOCASE ASC;";
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
        
        [installedPackages addObject:package];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
    return (NSArray*)installedPackages;
}

- (NSArray <ZBPackage *> *)searchForPackageName:(NSString *)name numberOfResults:(int)results {
    NSMutableArray *searchResults = [NSMutableArray new];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *query;
    
    if (results > 0) {
        query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE NAME LIKE \'%%%@\%%\' AND REPOID > -1 LIMIT %d;", name, results];
    }
    else {
        query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE NAME LIKE \'%%%@\%%\' AND REPOID > -1;", name];
    }
    
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
        
        [searchResults addObject:package];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
    return [self cleanUpDuplicatePackages:searchResults];
}

- (void)deleteRepo:(ZBRepo *)repo {
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *packageQuery = [NSString stringWithFormat:@"DELETE FROM PACKAGES WHERE REPOID = %d", [repo repoID]];
    NSString *repoQuery = [NSString stringWithFormat:@"DELETE FROM REPOS WHERE REPOID = %d", [repo repoID]];
    
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
    sqlite3_exec(database, [packageQuery UTF8String], NULL, NULL, NULL);
    sqlite3_exec(database, [repoQuery UTF8String], NULL, NULL, NULL);
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
    
    sqlite3_close(database);
}

- (NSArray *)otherVersionsForPackage:(ZBPackage *)package inDatabase:(sqlite3 *)database {
    NSMutableArray *otherVersions = [NSMutableArray new];
    
    NSString *query = @"SELECT * FROM PACKAGES WHERE PACKAGE = ?";
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[package identifier] UTF8String], -1, SQLITE_TRANSIENT);
    }
    while (sqlite3_step(statement) == SQLITE_ROW) {
        ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
        
        [otherVersions addObject:package];
    }
    sqlite3_finalize(statement);
    
    return (NSArray*)otherVersions;
}

- (NSMutableArray *)cleanUpDuplicatePackages:(NSArray *)packageList {
    NSMutableDictionary *packageVersionDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *cleanedPackageList = [packageList mutableCopy];
    
    for (ZBPackage *package in packageList) {
        if (packageVersionDict[[package identifier]] == NULL) {
            packageVersionDict[[package identifier]] = package;
        }
        
        NSString *arrayVersion = [(ZBPackage *)packageVersionDict[[package identifier]] version];
        NSString *packageVersion = [package version];
        int result = verrevcmp([packageVersion UTF8String], [arrayVersion UTF8String]);
        
        if (result > 0) {
            [cleanedPackageList removeObject:packageVersionDict[[package identifier]]];
            packageVersionDict[[package identifier]] = package;
        }
        else if (result < 0) {
            [cleanedPackageList removeObject:package];
        }
    }
    
    return cleanedPackageList;
}

- (void)saveIcon:(UIImage *)icon forRepo:(ZBRepo *)repo {
    const char* sqliteQuery = "UPDATE REPOS SET (ICON) = (?) WHERE REPOID = ?";
    sqlite3_stmt* statement;
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSData *imgData = UIImagePNGRepresentation(icon);
    
    if (sqlite3_prepare_v2(database, sqliteQuery, -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_blob(statement, 1, [imgData bytes], (int)[imgData length], SQLITE_TRANSIENT);
        sqlite3_bind_int(statement, 2, [repo repoID]);
        sqlite3_step(statement);
    }
    else {
        NSLog(@"[Zebra] Failed to save icon in database: %s", sqlite3_errmsg(database));
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(database);
}

- (UIImage *)iconForRepo:(ZBRepo *)repo {
    UIImage* icon = NULL;
    NSString* sqliteQuery = [NSString stringWithFormat:@"SELECT ICON FROM REPOS WHERE REPOID = %d;", [repo repoID]];
    sqlite3_stmt* statement;
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    if (sqlite3_prepare_v2(database, [sqliteQuery UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            int length = sqlite3_column_bytes(statement, 0);
            NSData *data = [NSData dataWithBytes:sqlite3_column_blob(statement, 0) length:length];
            icon = [UIImage imageWithData:data];
        }
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
    return icon;
}

- (NSDictionary *)sectionReadoutForRepo:(ZBRepo *)repo {
    NSMutableDictionary *sectionReadout = [NSMutableDictionary new];
    
    NSString *query = [NSString stringWithFormat:@"SELECT SECTION, COUNT(distinct package) as SECTION_COUNT from packages WHERE repoID = %d GROUP BY SECTION ORDER BY SECTION", [repo repoID]];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        const char *sectionChars = (const char *)sqlite3_column_text(statement, 0);
        if (sectionChars != 0) {
            NSString *section = [NSString stringWithUTF8String:sectionChars];
            [sectionReadout setObject:[NSNumber numberWithInt:sqlite3_column_int(statement, 1)] forKey:section];
        }
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
    return (NSDictionary *)sectionReadout;
}

- (int)numberOfPackagesFromRepo:(ZBRepo *)repo inSection:(NSString *)section {
    int packages = 0;
    
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(distinct package) FROM PACKAGES WHERE SECTION = \'%@\' AND REPOID = %d", section, [repo repoID]];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        packages = sqlite3_column_int(statement, 0);
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
    return packages;
}

- (void)dropTables {
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    char *packDel = "DROP TABLE PACKAGES;";
    sqlite3_exec(database, packDel, NULL, 0, NULL);
    char *repoDel = "DROP TABLE REPOS;";
    sqlite3_exec(database, repoDel, NULL, 0, NULL);
    
    sqlite3_close(database);
}

- (BOOL)packageIsInstalled:(ZBPackage *)package {
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    BOOL isInstalled = [self packageIsInstalled:package versionStrict:false inDatabase:database];
    sqlite3_close(database);
    
    return isInstalled;
}

- (BOOL)packageIsInstalled:(ZBPackage *)package versionStrict:(BOOL)strict inDatabase:(sqlite3 *)database {
    NSString *query;
    
    if (strict) {
        query = [NSString stringWithFormat:@"SELECT PACKAGE FROM PACKAGES WHERE PACKAGE = \'%@\' AND VERSION = \'%@\' AND REPOID < 1;", [package identifier], [package version]];
    }
    else {
        query = [NSString stringWithFormat:@"SELECT PACKAGE FROM PACKAGES WHERE PACKAGE = \'%@\' AND REPOID < 1;", [package identifier]];
    }
    
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        return true;
    }
    sqlite3_finalize(statement);
    
    return false;
}

- (BOOL)packageIsAvailable:(NSString *)package inDatabase:(sqlite3 *)database {
    NSString *query = [NSString stringWithFormat:@"SELECT PACKAGE FROM PACKAGES WHERE PACKAGE = \'%@\' AND REPOID != 0;", package];
    
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        return true;
    }
    sqlite3_finalize(statement);
    
    return false;
}

- (ZBPackage *)packageForID:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version inDatabase:(sqlite3 *)database {
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE = '\%@\';", identifier];
    
    ZBPackage *package;
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
        
        break;
    }
    
    //Only try to resolve "Provides" if we can't resolve the normal package.
    if (package == NULL) {
        query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PROVIDES LIKE \'%%%@\%%\';", identifier];
        sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
            
            break;
        }
    }
    sqlite3_finalize(statement);
    
    if (package != NULL) {
        NSArray *otherVersions = [self otherVersionsForPackage:package inDatabase:database];
        if ([otherVersions count] > 1) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
            NSArray *sorted = [otherVersions sortedArrayUsingDescriptors:@[sort]];
            
            for (ZBPackage *package in sorted) {
                if ([self doesPackage:package satisfyComparison:comparison ofVersion:version]) {
                    return package;
                }
            }
            
            return NULL;
        }
        else {
            return [self doesPackage:otherVersions[0] satisfyComparison:comparison ofVersion:version] ? otherVersions[0] : NULL;
        }
    }
    
    return NULL;
}

- (BOOL)doesPackage:(ZBPackage *)package satisfyComparison:(nonnull NSString *)comparison ofVersion:(nonnull NSString *)version {
    NSArray *choices = @[@"<<", @"<=", @"=", @">=", @">>"];
    
    if (version == NULL || comparison == NULL)
        return true;
    
    int nx = (int)[choices indexOfObject:comparison];
    switch (nx) {
        case 0:
            return [package compare:version] == NSOrderedAscending;
        case 1:
            return [package compare:version] == NSOrderedAscending || [package compare:version] == NSOrderedSame;
        case 2:
            return [package compare:version] == NSOrderedSame;
        case 3:
            return [package compare:version] == NSOrderedDescending || [package compare:version] == NSOrderedSame;
        case 4:
            return [package compare:version] == NSOrderedDescending;
        default:
            return false;
    }
}

- (NSArray <ZBPackage *>*)packagesWithUpdates {
    NSLog(@"[Zebra] Checking for package udaptes");
    NSMutableArray *packages = [NSMutableArray new];
    
    NSArray *installedPackage = [self installedPackages];
    for (ZBPackage *package in installedPackage) {
        ZBPackage *topVersion = [self topVersionForPackage:package];
        
        if ([topVersion compare:package] == NSOrderedDescending) {
            [packages addObject:topVersion];
        }
    }
    
    return (NSArray *)packages;
}

- (ZBPackage *)topVersionForPackage:(ZBPackage *)package {
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    NSArray *otherVersions = [self otherVersionsForPackage:package inDatabase:database];
    sqlite3_close(database);
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
    otherVersions = [otherVersions sortedArrayUsingDescriptors:@[sort]];
    
    return otherVersions[0];
}

@end
