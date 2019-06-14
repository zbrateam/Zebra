//
//  ZBDatabaseManager.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBDatabaseManager.h"
#import <Parsel/parsel.h>
#import <Parsel/vercmp.h>
#import <ZBAppDelegate.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Downloads/ZBDownloadManager.h>
#import <Database/ZBColumn.h>

@interface ZBDatabaseManager () {
    int numberOfDatabaseUsers;
    
    int numberOfUpdates;
    NSMutableArray *installedPackageIDs;
    NSMutableArray *upgradePackageIDs;
}
@end

@implementation ZBDatabaseManager

@synthesize needsToPresentRefresh;
@synthesize database;

+ (id)sharedInstance {
    static ZBDatabaseManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBDatabaseManager new];
        
        [instance openDatabase];
        
        //Checks to see if any of the databases have differing schemes and sets to update them if need be.
        [instance setNeedsToPresentRefresh:(needsMigration(instance.database, 0) != 0 || needsMigration(instance.database, 1) != 0 || needsMigration(instance.database, 2) != 0)];
        
        [instance closeDatabase];
    });
    return instance;
}

+ (NSDate *)lastUpdated {
    NSDate *lastUpdatedDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:@"lastUpdatedDate"];
    return lastUpdatedDate != NULL ? lastUpdatedDate : [NSDate distantPast];
}

- (id)init {
    self = [super init];

    if (self) {
        numberOfUpdates = 0;
    }

    return self;
}

#pragma mark - Opening and Closing the Database

- (int)openDatabase {
    if (![self isDatabaseOpen]) {
        sqlite3_shutdown();
        sqlite3_config(SQLITE_CONFIG_SERIALIZED);
        sqlite3_initialize();
        assert(sqlite3_threadsafe());
        int result = sqlite3_open_v2([[ZBAppDelegate databaseLocation] UTF8String], &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_CREATE, NULL);
        if (result == SQLITE_OK) {
            numberOfDatabaseUsers++;
        }
        return result;
    }
    else {
        numberOfDatabaseUsers++;
        return SQLITE_OK;
    }
}

- (int)closeDatabase {
    if (numberOfDatabaseUsers == 0) {
        return SQLITE_ERROR;
    }
    
    numberOfDatabaseUsers--;
    if (numberOfDatabaseUsers == 0 && [self isDatabaseOpen]) {
        int result = sqlite3_close(database);
        database = NULL;
        return result;
    }
    return SQLITE_OK;
}

- (BOOL)isDatabaseOpen {
    return numberOfDatabaseUsers > 0 || database != NULL;
}

- (void)printDatabaseError {
    const char *error = sqlite3_errmsg(database);
    if (error) {
        NSLog(@"[Zebra] Database Error: %s", error);
    }
}

#pragma mark - Populating the database

- (void)updateDatabaseUsingCaching:(BOOL)useCaching userRequested:(BOOL)requested {
    BOOL needsUpdate = false;
    if (!requested) {
        NSDate *currentDate = [NSDate date];
        NSDate *lastUpdatedDate = [ZBDatabaseManager lastUpdated];
        
        if (lastUpdatedDate != NULL) {
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags fromDate:lastUpdatedDate toDate:currentDate options:0];
            
            needsUpdate = ([components minute] >= 30); //might need to be less
        }
        else {
            needsUpdate = true;
        }
        
        
    }
    
    if (requested || needsUpdate) {
        [self->_databaseDelegate databaseStartedUpdate];
        ZBDownloadManager *downloadManager = [[ZBDownloadManager alloc] initWithDownloadDelegate:self sourceListPath:[ZBAppDelegate sourcesListPath]];
        if ([_databaseDelegate respondsToSelector:@selector(postStatusUpdate:atLevel:)])
            [_databaseDelegate postStatusUpdate:@"Updating Repositories\n" atLevel:ZBLogLevelInfo];
        
        [downloadManager downloadReposAndIgnoreCaching:!useCaching];
    }
    else {
        [self importLocalPackagesAndCheckForUpdates:true sender:self];
    }
}

- (void)parseRepos:(NSDictionary *)filenames {
    BOOL canPostStatus = [_databaseDelegate respondsToSelector:@selector(postStatusUpdate:atLevel:)];
    if (canPostStatus)
        [_databaseDelegate postStatusUpdate:@"Download Complete\n" atLevel:ZBLogLevelInfo];
    NSArray *releaseFiles = filenames[@"release"];
    NSArray *packageFiles = filenames[@"packages"];

    if (canPostStatus) {
        [_databaseDelegate postStatusUpdate:[NSString stringWithFormat:@"%d Release files need to be updated\n", (int)[releaseFiles count]] atLevel:ZBLogLevelInfo];
        [_databaseDelegate postStatusUpdate:[NSString stringWithFormat:@"%d Package files need to be updated\n", (int)[packageFiles count]] atLevel:ZBLogLevelInfo];
    }

    if ([self openDatabase] == SQLITE_OK) {
        for (NSString *releasePath in releaseFiles) {
            NSString *baseFileName = [[releasePath lastPathComponent] stringByReplacingOccurrencesOfString:@"_Release" withString:@""];
            
            int repoID = [self repoIDFromBaseFileName:baseFileName];
            if (repoID == -1) { //Repo does not exist in database, create it.
                repoID = [self nextRepoID];
                if (importRepoToDatabase([[ZBAppDelegate sourcesListPath] UTF8String], [releasePath UTF8String], database, repoID) != PARSEL_OK && canPostStatus) {
                    [_databaseDelegate postStatusUpdate:[NSString stringWithFormat:@"Error while opening file: %@\n", releasePath] atLevel:ZBLogLevelError];
                }
            }
            else {
                if (updateRepoInDatabase([[ZBAppDelegate sourcesListPath] UTF8String], [releasePath UTF8String], database, repoID) != PARSEL_OK && canPostStatus) {
                    [_databaseDelegate postStatusUpdate:[NSString stringWithFormat:@"Error while opening file: %@\n", releasePath] atLevel:ZBLogLevelError];
                }
            }
        }
        
        createTable(database, 1);
        sqlite3_exec(database, "CREATE TABLE PACKAGES_SNAPSHOT AS SELECT PACKAGE, VERSION, REPOID, LASTSEEN FROM PACKAGES WHERE REPOID > 0;", NULL, 0, NULL);
        sqlite3_exec(database, "CREATE INDEX tag_PACKAGEVERSION_SNAPSHOT ON PACKAGES_SNAPSHOT (PACKAGE, VERSION);", NULL, 0, NULL);
        sqlite3_int64 currentDate = (int)time(NULL);
        
        for (NSString *packagesPath in packageFiles) {
            NSString *baseFileName = [[packagesPath lastPathComponent] stringByReplacingOccurrencesOfString:@"_Packages" withString:@""];
            baseFileName = [baseFileName stringByReplacingOccurrencesOfString:@"_main_binary-iphoneos-arm" withString:@""];
            
            if ([_databaseDelegate respondsToSelector:@selector(setRepo:busy:)]) {
                [_databaseDelegate setRepo:baseFileName busy:true];
            }
            
            if (canPostStatus)
                [_databaseDelegate postStatusUpdate:[NSString stringWithFormat:@"Parsing %@\n", baseFileName] atLevel:0];
            
            int repoID = [self repoIDFromBaseFileName:baseFileName];
            if (repoID == -1) { //Repo does not exist in database, create it (this should never happen).
                NSLog(@"[Zebra] Repo for BFN %@ does not exist in the database.", baseFileName);
                repoID = [self nextRepoID];
                createDummyRepo([[ZBAppDelegate sourcesListPath] UTF8String], [packagesPath UTF8String], database, repoID); //For repos with no release file (notably junesiphone)
                if (updatePackagesInDatabase([packagesPath UTF8String], database, repoID, currentDate) != PARSEL_OK && canPostStatus) {
                    [_databaseDelegate postStatusUpdate:[NSString stringWithFormat:@"Error while opening file: %@\n", packagesPath] atLevel:ZBLogLevelError];
                }
            }
            else {
                if (updatePackagesInDatabase([packagesPath UTF8String], database, repoID, currentDate) != PARSEL_OK && canPostStatus) {
                    [_databaseDelegate postStatusUpdate:[NSString stringWithFormat:@"Error while opening file: %@\n", packagesPath] atLevel:ZBLogLevelError];
                }
            }
            
            if ([_databaseDelegate respondsToSelector:@selector(setRepo:busy:)]) {
                [_databaseDelegate setRepo:baseFileName busy:false];
            }
        }
        
        sqlite3_exec(database, "DROP TABLE PACKAGES_SNAPSHOT;", NULL, 0, NULL);
        
        if (canPostStatus)
            [_databaseDelegate postStatusUpdate:@"Done!\n" atLevel:ZBLogLevelInfo];
        
        [self importLocalPackagesAndCheckForUpdates:true sender:self];
        [self updateLastUpdated];
        [self->_databaseDelegate databaseCompletedUpdate:numberOfUpdates];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
        [self closeDatabase];
    }
    else {
        [self printDatabaseError];
    }
}

- (void)importLocalPackagesAndCheckForUpdates:(BOOL)checkForUpdates sender:(id)sender {
    BOOL needsDelegateStart = !([sender isKindOfClass:[ZBDatabaseManager class]]);
    if (needsDelegateStart) [self->_databaseDelegate databaseStartedUpdate];
    NSLog(@"[Zebra] Importing local packages");
    [self importLocalPackages];
    if (checkForUpdates) {
        NSLog(@"[Zebra] Checking for updates");
        [self checkForPackageUpdates];
    }
    if (needsDelegateStart) {
        [self->_databaseDelegate databaseCompletedUpdate:numberOfUpdates];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (void)importLocalPackages {
    NSString *installedPath;
    if ([ZBAppDelegate needsSimulation]) { //If the target is a simlator, load a demo list of installed packages
        installedPath = [[NSBundle mainBundle] pathForResource:@"Installed" ofType:@"pack"];
    }
    else { //Otherwise, load the actual file
        installedPath = @"/var/lib/dpkg/status";
    }
    
    if ([self openDatabase] == SQLITE_OK) {
        //Delete packages from local repos (-1 and 0)
        char *sql = "DELETE FROM PACKAGES WHERE REPOID = 0";
        sqlite3_exec(database, sql, NULL, 0, NULL);
        char *negativeOne = "DELETE FROM PACKAGES WHERE REPOID = -1";
        sqlite3_exec(database, negativeOne, NULL, 0, NULL);
        
        //Import packages from the installedPath
        importPackagesToDatabase([installedPath UTF8String], database, 0);
        
        [self closeDatabase];
    }
    else {
        [self printDatabaseError];
    }
}

- (void)checkForPackageUpdates {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *installedPackages = [NSMutableArray new];
        
        NSString *query = @"SELECT * FROM PACKAGES WHERE REPOID = 0;";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                
                [installedPackages addObject:package];
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);

        //Check for updates
        NSLog(@"[Zebra] Checking for updates...");
        NSMutableArray *found = [NSMutableArray new];
        
        createTable(database, 2);
        
        numberOfUpdates = 0;
        upgradePackageIDs = [NSMutableArray new];
        for (ZBPackage *package in installedPackages) {
            if ([found containsObject:[package identifier]]) {
                NSLog(@"[Zebra] I already checking %@, skipping", [package identifier]);
                continue;
            }
            BOOL packageIgnoreUpdates = [package ignoreUpdates];
            
            ZBPackage *topPackage = [self topVersionForPackage:package];
            NSComparisonResult compare = [package compare:topPackage];
            if (compare == NSOrderedAscending) {
                NSLog(@"[Zebra] Installed package %@ is less than top package %@, it needs an update", package, topPackage);
                
                BOOL ignoreUpdates = [topPackage ignoreUpdates];
                if (!ignoreUpdates) numberOfUpdates++;
                NSString *query = [NSString stringWithFormat:@"REPLACE INTO UPDATES(PACKAGE, VERSION, IGNORE) VALUES(\'%@\', \'%@\', %d);", [topPackage identifier], [topPackage version], ignoreUpdates ? 1 : 0];
                
                if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                        break;
                    }
                }
                else {
                    [self printDatabaseError];
                }
                sqlite3_finalize(statement);
                
                [upgradePackageIDs addObject:[topPackage identifier]];
            }
            else if (compare == NSOrderedSame) {
                NSString *query;
                if (packageIgnoreUpdates)
                    // This package has no update and the user actively ignores updates from it, we update the latest version here
                    query = [NSString stringWithFormat:@"REPLACE INTO UPDATES(PACKAGE, VERSION, IGNORE) VALUES(\'%@\', \'%@\', 1);", [package identifier], [package version]];
                else
                    // This package has no update and the user does not ignore updates from it, having the record in the database is waste of space
                    query = [NSString stringWithFormat:@"DELETE FROM UPDATES WHERE PACKAGE = \'%@\';", [package identifier]];
                if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                        break;
                    }
                }
                else {
                    [self printDatabaseError];
                }
                sqlite3_finalize(statement);
            }
            [found addObject:[package identifier]];
        }
        [self closeDatabase];
    }
    else {
        [self printDatabaseError];
    }
}

- (void)dropTables {
    if ([self openDatabase] == SQLITE_OK) {
        char *packDel = "DROP TABLE PACKAGES;";
        sqlite3_exec(database, packDel, NULL, 0, NULL);
        char *repoDel = "DROP TABLE REPOS;";
        sqlite3_exec(database, repoDel, NULL, 0, NULL);
        char *updatesDel = "DROP TABLE UPDATES;";
        sqlite3_exec(database, updatesDel, NULL, 0, NULL);
        
        [self closeDatabase];
    }
    else {
        [self printDatabaseError];
    }
}

- (void)updateLastUpdated {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastUpdatedDate"];
}

#pragma mark - Repo management

- (int)repoIDFromBaseFileName:(NSString *)bfn {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT REPOID FROM REPOS WHERE BASEFILENAME = \'%@\'", bfn];
        
        sqlite3_stmt *statement;
        int repoID = -1;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                repoID = sqlite3_column_int(statement, 0);
                break;
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return repoID;
    }
    else {
        [self printDatabaseError];
        return -1;
    }
}

- (int)nextRepoID {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query = @"SELECT REPOID FROM REPOS ORDER BY REPOID DESC LIMIT 1";
        
        sqlite3_stmt *statement;
        int repoID = 0;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                repoID = sqlite3_column_int(statement, 0);
                break;
            }
        }
        else {
            [self printDatabaseError];
        }
        
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return repoID + 1;
    }
    else {
        [self printDatabaseError];
        return -1;
    }
}

- (int)numberOfPackagesInRepo:(ZBRepo * _Nullable)repo section:(NSString * _Nullable)section {
    if ([self openDatabase] == SQLITE_OK) {
        int packages = 0;
        NSString *query;
        NSString *repoPart = repo ? [NSString stringWithFormat:@"REPOID = %d", [repo repoID]] : @"REPOID > 0";
        if (section != NULL) {
            query = [NSString stringWithFormat:@"SELECT COUNT(distinct package) FROM PACKAGES WHERE SECTION = \'%@\' AND %@", section, repoPart];
        }
        else {
            query = [NSString stringWithFormat:@"SELECT COUNT(distinct package) FROM PACKAGES WHERE %@", repoPart];
        }
        
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                packages = sqlite3_column_int(statement, 0);
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return packages;
    }
    else {
        [self printDatabaseError];
        return -1;
    }
}

- (NSArray <ZBRepo *> *)repos {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *sources = [NSMutableArray new];
        
        NSString *query = @"SELECT * FROM REPOS ORDER BY ORIGIN COLLATE NOCASE ASC";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBRepo *source = [[ZBRepo alloc] initWithSQLiteStatement:statement];
                
                [sources addObject:source];
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return (NSArray*)sources;
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
}

- (void)deleteRepo:(ZBRepo *)repo {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *packageQuery = [NSString stringWithFormat:@"DELETE FROM PACKAGES WHERE REPOID = %d", [repo repoID]];
        NSString *repoQuery = [NSString stringWithFormat:@"DELETE FROM REPOS WHERE REPOID = %d", [repo repoID]];
        
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
        sqlite3_exec(database, [packageQuery UTF8String], NULL, NULL, NULL);
        sqlite3_exec(database, [repoQuery UTF8String], NULL, NULL, NULL);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
        
        [self closeDatabase];
    }
    else {
        [self printDatabaseError];
    }
}

- (UIImage *)iconForRepo:(ZBRepo *)repo {
    if ([self openDatabase] == SQLITE_OK) {
        UIImage* icon = NULL;
        NSString* sqliteQuery = [NSString stringWithFormat:@"SELECT ICON FROM REPOS WHERE REPOID = %d;", [repo repoID]];
        sqlite3_stmt* statement;
        
        if (sqlite3_prepare_v2(database, [sqliteQuery UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                int length = sqlite3_column_bytes(statement, 0);
                NSData *data = [NSData dataWithBytes:sqlite3_column_blob(statement, 0) length:length];
                icon = [UIImage imageWithData:data];
            }
        }
        
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return icon;
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
}

- (void)saveIcon:(UIImage *)icon forRepo:(ZBRepo *)repo {
    if ([self openDatabase] == SQLITE_OK) {
        const char* sqliteQuery = "UPDATE REPOS SET (ICON) = (?) WHERE REPOID = ?";
        sqlite3_stmt* statement;
        
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
        [self closeDatabase];
    }
    else {
        [self printDatabaseError];
    }
}

- (NSDictionary *)sectionReadoutForRepo:(ZBRepo *)repo {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableDictionary *sectionReadout = [NSMutableDictionary new];
        
        NSString *query = [NSString stringWithFormat:@"SELECT SECTION, COUNT(distinct package) as SECTION_COUNT from packages WHERE repoID = %d GROUP BY SECTION ORDER BY SECTION", [repo repoID]];
        
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *sectionChars = (const char *)sqlite3_column_text(statement, 0);
                if (sectionChars != 0) {
                    NSString *section = [NSString stringWithUTF8String:sectionChars];
                    [sectionReadout setObject:[NSNumber numberWithInt:sqlite3_column_int(statement, 1)] forKey:section];
                }
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return (NSDictionary *)sectionReadout;
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
}

#pragma mark - Package management

- (NSArray <ZBPackage *> *)packagesFromRepo:(ZBRepo * _Nullable)repo inSection:(NSString * _Nullable)section numberOfPackages:(int)limit startingAt:(int)start {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *packages = [NSMutableArray new];
        NSString *query;
        
        if (section == NULL) {
            NSString *repoPart = repo ? [NSString stringWithFormat:@"WHERE REPOID = %d", [repo repoID]] : @"WHERE REPOID > 0";
            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES %@ LIMIT %d OFFSET %d", repoPart, limit, start];
        }
        else {
            NSString *repoPart = repo ? [NSString stringWithFormat:@"AND REPOID = %d", [repo repoID]] : @"AND REPOID > 0";
            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE SECTION = '\%@\' %@ LIMIT %d OFFSET %d", section, repoPart, limit, start];
        }
        
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                
                [packages addObject:package];
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return [self cleanUpDuplicatePackages:packages];
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
}

- (NSMutableArray <ZBPackage *> *)installedPackages {
    if ([self openDatabase] == SQLITE_OK) {
        installedPackageIDs = [NSMutableArray new];
        NSMutableArray *installedPackages = [NSMutableArray new];
        
        NSString *query = @"SELECT * FROM PACKAGES WHERE REPOID = 0;";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                
                [installedPackageIDs addObject:[package identifier]];
                [installedPackages addObject:package];
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return installedPackages;
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
}

- (NSMutableArray <ZBPackage *>*)packagesWithUpdatesIncludingIgnored:(BOOL)ignored {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *packagesWithUpdates = [NSMutableArray new];
        NSString *query = @"SELECT * FROM UPDATES;";
        
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *identifierChars = (const char *)sqlite3_column_text(statement, ZBUpdateColumnID);
                const char *versionChars = (const char *)sqlite3_column_text(statement, ZBUpdateColumnVersion);
                NSString *identifier = [NSString stringWithUTF8String:identifierChars];
                if ((ignored || sqlite3_column_int(statement, ZBUpdateColumnIgnore) == 0) && versionChars != 0) {
                    NSString *version = [NSString stringWithUTF8String:versionChars];
                    
                    ZBPackage *package = [self packageForID:identifier equalVersion:version];
                    if (package != NULL) [packagesWithUpdates addObject:package];
                }
                else if ([upgradePackageIDs containsObject:identifier]) {
                    [upgradePackageIDs removeObject:identifier];
                }
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return packagesWithUpdates;
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
}

- (NSMutableArray <ZBPackage *>*)packagesWithUpdates {
    return [self packagesWithUpdatesIncludingIgnored:NO];
}

- (NSArray <ZBPackage *> *)searchForPackageName:(NSString *)name numberOfResults:(int)results {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *searchResults = [NSMutableArray new];
        NSString *query;
        
        if (results > 0) {
            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE NAME LIKE \'%%%@\%%\' AND REPOID > -1 LIMIT %d;", name, results];
        }
        else {
            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE NAME LIKE \'%%%@\%%\' AND REPOID > -1 ORDER BY NAME COLLATE NOCASE ASC;", name];
        }
        
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                
                [searchResults addObject:package];
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return [self cleanUpDuplicatePackages:searchResults];
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
}

- (NSArray <ZBPackage *> *)purchasedPackages:(NSArray <NSString *> *)requestedPackages {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *packages = [NSMutableArray new];
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE IN ('\%@') ORDER BY NAME COLLATE NOCASE ASC", [requestedPackages componentsJoinedByString:@"','"]];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                
                [packages addObject:package];
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return [self cleanUpDuplicatePackages:packages];
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
}

#pragma mark - Package status

- (BOOL)packageIDHasUpdate:(NSString *)packageIdentifier {
    if ([upgradePackageIDs count] != 0) {
        return [upgradePackageIDs containsObject:packageIdentifier];
    }
    else {
        if ([self openDatabase] == SQLITE_OK) {
            NSString *query = [NSString stringWithFormat:@"SELECT PACKAGE FROM UPDATES WHERE PACKAGE = \'%@\' AND IGNORE = 0 LIMIT 1;", packageIdentifier];
            
            BOOL packageIsInstalled = false;
            sqlite3_stmt *statement;
            if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    packageIsInstalled = true;
                    break;
                }
            }
            else {
                [self printDatabaseError];
            }
            sqlite3_finalize(statement);
            [self closeDatabase];
            
            return packageIsInstalled;
        }
        else {
            [self printDatabaseError];
            return false;
        }
    }
}

- (BOOL)packageHasUpdate:(ZBPackage *)package {
    return [self packageIDHasUpdate:[package identifier]];
}

- (BOOL)packageIDIsInstalled:(NSString *)packageIdentifier version:(NSString *_Nullable)version {
    if (version == NULL && [installedPackageIDs count] != 0) {
        return [installedPackageIDs containsObject:packageIdentifier];
    }
    else {
        if ([self openDatabase] == SQLITE_OK) {
            NSString *query;
            
            if (version != NULL) {
                query = [NSString stringWithFormat:@"SELECT PACKAGE FROM PACKAGES WHERE PACKAGE = \'%@\' AND VERSION = \'%@\' AND REPOID < 1 LIMIT 1;", packageIdentifier, version];
            }
            else {
                query = [NSString stringWithFormat:@"SELECT PACKAGE FROM PACKAGES WHERE PACKAGE = \'%@\' AND REPOID < 1 LIMIT 1;", packageIdentifier];
            }
            
            BOOL packageIsInstalled = false;
            sqlite3_stmt *statement;
            if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    packageIsInstalled = true;
                    break;
                }
            }
            else {
                [self printDatabaseError];
            }
            sqlite3_finalize(statement);
            [self closeDatabase];
            
            return packageIsInstalled;
        }
        else {
            [self printDatabaseError];
            return false;
        }
    }
}

- (BOOL)packageIsInstalled:(ZBPackage *)package versionStrict:(BOOL)strict {
    return [self packageIDIsInstalled:[package identifier] version:strict ? [package version] : NULL];
}

- (BOOL)packageIDIsAvailable:(NSString *)packageIdentifier version:(NSString *_Nullable)version {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT PACKAGE FROM PACKAGES WHERE PACKAGE = \'%@\' AND REPOID > 0 LIMIT 1;", packageIdentifier];
        
        BOOL packageIsAvailable = false;
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                packageIsAvailable = true;
                break;
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return packageIsAvailable;
    }
    else {
        [self printDatabaseError];
        return false;
    }
}

- (BOOL)packageIsAvailable:(ZBPackage *)package versionStrict:(BOOL)strict {
    return [self packageIDIsAvailable:[package identifier] version:strict ? [package version] : NULL];
}

- (ZBPackage *)packageForID:(NSString *)identifier equalVersion:(NSString *)version {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE = '\%@\' AND VERSION = \'%@\' LIMIT 1;", identifier, version];
        
        ZBPackage *package;
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                
                break;
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return package;
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
}

- (BOOL)areUpdatesIgnoredForPackage:(ZBPackage *)package {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT IGNORE FROM UPDATES WHERE PACKAGE = '\%@\' LIMIT 1;", [package identifier]];
        
        BOOL ignored = false;
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                if (sqlite3_column_int(statement, 0) == 1)
                    ignored = true;
                break;
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return ignored;
    }
    else {
        [self printDatabaseError];
        return false;
    }
}

- (void)setUpdatesIgnored:(BOOL)ignore forPackage:(ZBPackage *)package {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"REPLACE INTO UPDATES(PACKAGE, VERSION, IGNORE) VALUES(\'%@\', \'%@\', %d);", [package identifier], [package version], ignore ? 1 : 0];
        
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                break;
            }
        }
        else {
            NSLog(@"[Zebra] Error preparing setting package ignore updates statement: %s", sqlite3_errmsg(database));
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
    }
    else {
        [self printDatabaseError];
    }
}

#pragma mark - Package lookup

- (ZBPackage *)packageThatProvides:(NSString *)identifier checkInstalled:(BOOL)installed {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query;
        if (installed) {
            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PROVIDES LIKE \'%%%@\%%\' LIMIT 1;", identifier];
        }
        else {
            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PROVIDES LIKE \'%%%@\%%\' AND REPOID > 0 LIMIT 1;", identifier];
        }
        ZBPackage *package;
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                break;
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        return package;
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
}

- (ZBPackage *)packageForID:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version checkInstalled:(BOOL)installed checkProvides:(BOOL)provides {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query;
        if (installed) {
            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE = '\%@\' LIMIT 1;", identifier];
        }
        else {
            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE = '\%@\' AND REPOID > 0 LIMIT 1;", identifier];
        }
        
        ZBPackage *package;
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                break;
            }
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        //Only try to resolve "Provides" if we can't resolve the normal package.
        if (provides && package == NULL) {
            package = [self packageThatProvides:identifier checkInstalled:installed];
        }
        
        
        if (package != NULL) {
            NSArray *otherVersions = [self allVersionsForPackage:package];
            if ([otherVersions count] > 1) {
                for (ZBPackage *package in otherVersions) {
//                    if ([[package repo] repoID] == 0) continue;
                    if ([self doesPackage:package satisfyComparison:comparison ofVersion:version]) {
                        [self closeDatabase];
                        return package;
                    }
                }
                
                [self closeDatabase];
                return NULL;
            }
            else {
                [self closeDatabase];
                return [self doesPackage:otherVersions[0] satisfyComparison:comparison ofVersion:version] ? otherVersions[0] : NULL;
            }
        }
        
        [self closeDatabase];
        return NULL;
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
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

- (NSArray *)allVersionsForPackage:(ZBPackage *)package {
    return [self allVersionsForPackageID:[package identifier]];
}

- (NSArray *)allVersionsForPackageID:(NSString *)packageIdentifier {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *allVersions = [NSMutableArray new];
        
        NSString *query = @"SELECT * FROM PACKAGES WHERE PACKAGE = ?;";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
        }
        while (sqlite3_step(statement) == SQLITE_ROW) {
            ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
            
            [allVersions addObject:package];
        }
        sqlite3_finalize(statement);
        
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        NSArray *sorted = [allVersions sortedArrayUsingDescriptors:@[sort]];
        [self closeDatabase];
        
        return sorted;
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
}


- (NSArray *)otherVersionsForPackage:(ZBPackage *)package {
    return [self otherVersionsForPackageID:[package identifier] version:[package version]];
}

- (NSArray *)otherVersionsForPackageID:(NSString *)packageIdentifier version:(NSString *)version {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *otherVersions = [NSMutableArray new];
        
        NSString *query = @"SELECT * FROM PACKAGES WHERE PACKAGE = ? AND VERSION != ?;";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [version UTF8String], -1, SQLITE_TRANSIENT);
        }
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int repoID = sqlite3_column_int(statement, ZBPackageColumnRepoID);
            if (repoID > 0) {
                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                
                [otherVersions addObject:package];
            }
        }
        sqlite3_finalize(statement);
        
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        NSArray *sorted = [otherVersions sortedArrayUsingDescriptors:@[sort]];
        [self closeDatabase];
        
        return sorted;
    }
    else {
        [self printDatabaseError];
        return NULL;
    }
}


- (nullable ZBPackage *)topVersionForPackage:(ZBPackage *)package {
    return [self topVersionForPackageID:[package identifier]];
}

- (nullable ZBPackage *)topVersionForPackageID:(NSString *)packageIdentifier {
    NSArray *allVersions = [self allVersionsForPackageID:packageIdentifier];
    
    return allVersions.count ? allVersions[0] : nil;
}

#pragma mark - Hyena Delegate

- (void)predator:(nonnull ZBDownloadManager *)downloadManager finishedAllDownloads:(nonnull NSDictionary *)filenames {
    [self parseRepos:filenames];
}

- (void)predator:(nonnull ZBDownloadManager *)downloadManager startedDownloadForFile:(nonnull NSString *)filename {
    if ([_databaseDelegate respondsToSelector:@selector(setRepo:busy:)]) {
        [_databaseDelegate setRepo:filename busy:true];
    }
    
    if ([_databaseDelegate respondsToSelector:@selector(postStatusUpdate:atLevel:)])
        [_databaseDelegate postStatusUpdate:[NSString stringWithFormat:@"Downloading %@\n", filename] atLevel:ZBLogLevelDescript];
}

- (void)predator:(nonnull ZBDownloadManager *)downloadManager finishedDownloadForFile:(nonnull NSString *)filename withError:(NSError * _Nullable)error {
    if ([_databaseDelegate respondsToSelector:@selector(setRepo:busy:)]) {
        [_databaseDelegate setRepo:filename busy:false];
    }
    
    if ([_databaseDelegate respondsToSelector:@selector(postStatusUpdate:atLevel:)]) {
        if (error != NULL) {
            [_databaseDelegate postStatusUpdate:[NSString stringWithFormat:@"%@ for %@ \n", error.localizedDescription, filename] atLevel:ZBLogLevelError];
        }
        else {
            [_databaseDelegate postStatusUpdate:[NSString stringWithFormat:@"Done %@\n", filename] atLevel:ZBLogLevelDescript];
        }
    }
}

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    if ([_databaseDelegate respondsToSelector:@selector(postStatusUpdate:atLevel:)]) {
        NSLog(@"[Zebra] I'll forward your request... %@", status);
        [_databaseDelegate postStatusUpdate:status atLevel:level];
    }
}

#pragma mark - Helper methods

- (NSArray *)cleanUpDuplicatePackages:(NSMutableArray *)packageList {
    NSMutableDictionary *packageVersionDict = [[NSMutableDictionary alloc] init];
    
    for (ZBPackage *package in packageList) {
        ZBPackage *packageFromDict = packageVersionDict[[package identifier]];
        if (packageFromDict == NULL) {
            packageVersionDict[[package identifier]] = package;
            continue;
        }
        
        if ([package sameAs:packageFromDict]) {
            NSString *packageDictVersion = [packageFromDict version];
            NSString *packageVersion = [package version];
            int result = compare([packageVersion UTF8String], [packageDictVersion UTF8String]);
            
            if (result > 0) {
                packageVersionDict[[package identifier]] = package;
            }
        }
    }
    
    return [packageVersionDict allValues];
}

@end
