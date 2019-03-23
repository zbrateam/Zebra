//
//  ZBDatabaseManager.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBDatabaseManager.h"
#import <Parsel/Parsel.h>
#import <sqlite3.h>
#import <NSTask.h>
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

- (void)updateDatabaseUsingCaching:(BOOL)useCaching completion:(void (^)(BOOL success, NSError *error))completion {
    [self postStatusUpdate:@"Updating Repositories\n" atLevel:1];
    Hyena *predator = [[Hyena alloc] initWithSourceListPath:[ZBAppDelegate sourceListLocation]];
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
            completion(success, NULL);
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

- (int)numberOfPackagesInRepo:(int)repoID {
    int numberOfPackages = 0;
    
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM PACKAGES WHERE REPOID = %d GROUP BY PACKAGE", repoID];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        numberOfPackages++;
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
        const char *originChars = (const char *)sqlite3_column_text(statement, 0);
        const char *descriptionChars = (const char *)sqlite3_column_text(statement, 1);
        const char *baseFilenameChars = (const char *)sqlite3_column_text(statement, 2);
        const char *baseURLChars = (const char *)sqlite3_column_text(statement, 3);
        const char *suiteChars = (const char *)sqlite3_column_text(statement, 7);
        const char *compChars = (const char *)sqlite3_column_text(statement, 8);
        
        NSURL *iconURL;
        NSString *baseURL = [[NSString alloc] initWithUTF8String:baseURLChars];
        NSArray *separate = [baseURL componentsSeparatedByString:@"dists"];
        NSString *shortURL = separate[0];
        
        NSString *url = [baseURL stringByAppendingPathComponent:@"CydiaIcon.png"];
        if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) {
            iconURL = [NSURL URLWithString:url] ;
        }
        else{
            iconURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", url]] ;
        }
        
        ZBRepo *source = [[ZBRepo alloc] initWithOrigin:[[NSString alloc] initWithUTF8String:originChars] description:[[NSString alloc] initWithUTF8String:descriptionChars] baseFileName:[[NSString alloc] initWithUTF8String:baseFilenameChars] baseURL:baseURL secure:sqlite3_column_int(statement, 4) repoID:sqlite3_column_int(statement, 5) iconURL:iconURL isDefault:sqlite3_column_int(statement, 6) suite:[[NSString alloc] initWithUTF8String:suiteChars] components:[[NSString alloc] initWithUTF8String:compChars] shortURL:shortURL];
        
        [sources addObject:source];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
    return (NSArray*)sources;
}

- (NSArray <ZBPackage *> *)packagesFromRepo:(int)repoID numberOfPackages:(int)limit startingAt:(int)start {
    NSMutableArray *packages = [NSMutableArray new];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE REPOID = %d ORDER BY NAME COLLATE NOCASE ASC LIMIT %d OFFSET %d", repoID, limit, start];
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        const char *packageIDChars = (const char *)sqlite3_column_text(statement, 0);
        const char *packageNameChars = (const char *)sqlite3_column_text(statement, 1);
        const char *versionChars = (const char *)sqlite3_column_text(statement, 2);
        const char *descriptionChars = (const char *)sqlite3_column_text(statement, 3);
        const char *sectionChars = (const char *)sqlite3_column_text(statement, 4);
        const char *depictionChars = (const char *)sqlite3_column_text(statement, 5);
        
        ZBPackage *package = [[ZBPackage alloc] initWithIdentifier:[[NSString alloc] initWithUTF8String:packageIDChars] name:[[NSString alloc] initWithUTF8String:packageNameChars] version:[[NSString alloc] initWithUTF8String:versionChars] description:[[NSString alloc] initWithUTF8String:descriptionChars] section:[[NSString alloc] initWithUTF8String:sectionChars] depictionURL:[[NSString alloc] initWithUTF8String:depictionChars] installed:false remote:true];
        
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
        const char *packageIDChars = (const char *)sqlite3_column_text(statement, 0);
        const char *packageNameChars = (const char *)sqlite3_column_text(statement, 1);
        const char *versionChars = (const char *)sqlite3_column_text(statement, 2);
        const char *descriptionChars = (const char *)sqlite3_column_text(statement, 3);
        const char *sectionChars = (const char *)sqlite3_column_text(statement, 4);
        const char *depictionChars = (const char *)sqlite3_column_text(statement, 5);
        
        ZBPackage *package = [[ZBPackage alloc] initWithIdentifier:[[NSString alloc] initWithUTF8String:packageIDChars] name:[[NSString alloc] initWithUTF8String:packageNameChars] version:[[NSString alloc] initWithUTF8String:versionChars] description:[[NSString alloc] initWithUTF8String:descriptionChars] section:[[NSString alloc] initWithUTF8String:sectionChars] depictionURL:[[NSString alloc] initWithUTF8String:depictionChars] installed:true remote:false];
        
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
        query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE NAME LIKE \'%%%@\%%\' LIMIT %d", name, results];
    }
    else {
        query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE NAME LIKE \'%%%@\%%\'", name];
    }
    
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        const char *packageIDChars = (const char *)sqlite3_column_text(statement, 0);
        const char *packageNameChars = (const char *)sqlite3_column_text(statement, 1);
        const char *versionChars = (const char *)sqlite3_column_text(statement, 2);
        const char *descriptionChars = (const char *)sqlite3_column_text(statement, 3);
        const char *sectionChars = (const char *)sqlite3_column_text(statement, 4);
        const char *depictionChars = (const char *)sqlite3_column_text(statement, 5);
        
        ZBPackage *package = [[ZBPackage alloc] initWithIdentifier:[[NSString alloc] initWithUTF8String:packageIDChars] name:[[NSString alloc] initWithUTF8String:packageNameChars] version:[[NSString alloc] initWithUTF8String:versionChars] description:[[NSString alloc] initWithUTF8String:descriptionChars] section:[[NSString alloc] initWithUTF8String:sectionChars] depictionURL:[[NSString alloc] initWithUTF8String:depictionChars] installed:false remote:false];
        
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

- (void)getPackagesThatNeedUpdates:(void (^)(NSArray *updates, BOOL hasUpdates))completion {
    NSLog(@"pcakages need updates");
    NSMutableArray *updates = [NSMutableArray new];
    NSArray *installedPackages = [self installedPackages];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    for (ZBPackage *package in installedPackages) {
        NSArray *otherVersions = [self otherVersionsForPackage:package inDatabase:database];
        if ([otherVersions count] > 1) {
            for (ZBPackage *otherPackage in otherVersions) {
                if (otherPackage != package) {
                    int result = verrevcmp([[package version] UTF8String], [[otherPackage version] UTF8String]);
                    
                    if (result < 0) {
                        [updates addObject:otherPackage];
                    }
                }
            }
        }
    }
    
    updates = [self cleanUpDuplicatePackages:updates];
    sqlite3_close(database);
    if (updates.count > 0) {
        completion(updates, true);
    }
    else {
        completion(NULL, false);
    }
}

- (NSArray *)otherVersionsForPackage:(ZBPackage *)package inDatabase:(sqlite3 *)database {
    NSMutableArray *otherVersions = [NSMutableArray new];
    
    NSString *query = @"SELECT * FROM PACKAGES WHERE PACKAGE = ?";
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[package identifier] UTF8String], -1, SQLITE_TRANSIENT);
    }
    while (sqlite3_step(statement) == SQLITE_ROW) {
        const char *packageIDChars = (const char *)sqlite3_column_text(statement, 0);
        const char *packageNameChars = (const char *)sqlite3_column_text(statement, 1);
        const char *versionChars = (const char *)sqlite3_column_text(statement, 2);
        const char *descriptionChars = (const char *)sqlite3_column_text(statement, 3);
        const char *sectionChars = (const char *)sqlite3_column_text(statement, 4);
        const char *depictionChars = (const char *)sqlite3_column_text(statement, 5);
        
        ZBPackage *package = [[ZBPackage alloc] initWithIdentifier:[[NSString alloc] initWithUTF8String:packageIDChars] name:[[NSString alloc] initWithUTF8String:packageNameChars] version:[[NSString alloc] initWithUTF8String:versionChars] description:[[NSString alloc] initWithUTF8String:descriptionChars] section:[[NSString alloc] initWithUTF8String:sectionChars] depictionURL:[[NSString alloc] initWithUTF8String:depictionChars] installed:true remote:false];
        
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

@end
