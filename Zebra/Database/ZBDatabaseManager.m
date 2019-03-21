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

- (void)fullImport:(void (^)(BOOL success, NSArray* updates, BOOL hasUpdates))completion {
    //Refresh repos
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @1, @"message": @"Importing Remote APT Repositories...\n"}];
    [self fullRemoteImport:^(BOOL success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @1, @"message": @"Importing Local Packages...\n"}];
        [self fullLocalImport:^(BOOL success) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @1, @"message": @"Done.\n"}];
            [self getPackagesThatNeedUpdates:^(NSArray <ZBPackage *> *updateObjects, BOOL has) {
                if (has) {
                    NSLog(@"[Zebra] Has %d Updates!", (int)[updateObjects count]);
                }
                completion(true, updateObjects, has);
            }];
        }];
    }];
}

- (void)partialImport:(void (^)(BOOL success, NSArray* updates, BOOL hasUpdates))completion {
    if ([ZBAppDelegate needsSimulation]) {
        [self fullImport:^(BOOL success, NSArray *updates, BOOL hasUpdates) {
            completion(success, updates, hasUpdates);
        }];
    }
    else {
        NSLog(@"Beginning partial import of repos");
        [self partialRemoteImport:^(BOOL success) {
            NSLog(@"Done.");
            [self updateEssentials:^(BOOL success, NSArray * _Nonnull updates, BOOL hasUpdates) {
                completion(success, updates, hasUpdates);
            }];
        }];
    }
}

//Imports packages from repositories located in /var/lib/zebra/lists
- (void)fullRemoteImport:(void (^)(BOOL success))completion {
    NSLog(@"[Hyena] Predatory.");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @1, @"message": @"Updating Repositories...\n"}];
    
    NSString *sourcePath = [ZBAppDelegate needsSimulation] ? [[NSBundle mainBundle] pathForResource:@"sources" ofType:@"list"] : @"/var/lib/zebra/sources.list";
    NSDate *methodStart = [NSDate date];
    Hyena *hyena = [[Hyena alloc] initWithSourceListPath:sourcePath];
    [hyena downloadReposWithCompletion:^(NSArray *fileNames, BOOL success) {
        NSLog(@"[Hyena] Update Complete.");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @1, @"message": @"APT Repository Update Complete.\n"}];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @1, @"message": @"Beginning to parse repos into Database.\n"}];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"zebra.db"];
        
        sqlite3 *database;
        sqlite3_open([databasePath UTF8String], &database);
        
        sqlite3_exec(database, "DELETE FROM REPOS; DELETE FROM PACKAGES", NULL, NULL, NULL);
        int i = 1;
        for (NSString *path in fileNames) {
//            NSLog(@"[Zebra] Repo: %@ %d", path, i);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @0, @"message": [NSString stringWithFormat:@"Parsing %@\n", path]}];
            importRepoToDatabase([path UTF8String], database, i);
            
            NSString *baseFileName = [path stringByReplacingOccurrencesOfString:@"_Release" withString:@""];
            NSString *packageFile = [NSString stringWithFormat:@"%@_Packages", baseFileName];
            if (![[NSFileManager defaultManager] fileExistsAtPath:packageFile]) {
                //CHANGE THIS BACK
                packageFile = [NSString stringWithFormat:@"%@_main_binary-iphoneos-arm_Packages", baseFileName]; //Do some funky package file with the default repos
            }
//            NSLog(@"[Zebra] Packages: %@ %d", packageFile, i);
            importPackagesToDatabase([packageFile UTF8String], database, i);
            i++;
        }
        sqlite3_close(database);
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
        NSLog(@"[Zebra] Time to download, parse, and import %d repos = %f", i - 1, executionTime);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @0, @"message": [NSString stringWithFormat:@"Imported %d repos in %f seconds\n", i - 1, executionTime]}];
        
        completion(true);
    }];
}

- (void)receivedData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];
    
    if (data.length > 0) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @0, @"message": str}];
    }
}

- (void)receivedErrorData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];
    
    if (data.length > 0) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @2, @"message": str}];
    }
}

//Imports packages in /var/lib/dpkg/status into Zebra's database with a repoValue of '0' to indicate that the package is installed
- (void)fullLocalImport:(void (^)(BOOL success))completion {
    NSString *installedPath;
    if ([ZBAppDelegate needsSimulation]) { //If the target is a simlator, load a demo list of installed packages
        installedPath = [[NSBundle mainBundle] pathForResource:@"Installed" ofType:@"pack"];
    }
    else { //Otherwise, load the actual file
        installedPath = @"/var/lib/dpkg/status";
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"zebra.db"];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    //We need to delete the entire list of installed packages
    
    char *sql = "DELETE FROM PACKAGES WHERE REPOID = 0";
    sqlite3_exec(database, sql, NULL, 0, NULL);
    importPackagesToDatabase([installedPath UTF8String], database, 0);
    sqlite3_close(database);
    completion(true);
}

- (void)partialRemoteImport:(void (^)(BOOL success))completion {
    NSTask *removeCacheTask = [[NSTask alloc] init];
    [removeCacheTask setLaunchPath:@"/Applications/Zebra.app/supersling"];
    NSArray *rmArgs = [[NSArray alloc] initWithObjects: @"rm", @"-rf", @"/var/mobile/Library/Caches/xyz.willy.Zebra/lists", nil];
    [removeCacheTask setArguments:rmArgs];
    
    [removeCacheTask launch];
    [removeCacheTask waitUntilExit];
    
    NSTask *cpTask = [[NSTask alloc] init];
    [cpTask setLaunchPath:@"/Applications/Zebra.app/supersling"];
    NSArray *cpArgs = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/zebra/lists", @"/var/mobile/Library/Caches/xyz.willy.Zebra/", nil];
    [cpTask setArguments:cpArgs];
    
    [cpTask launch];
    [cpTask waitUntilExit];
    
    NSTask *refreshTask = [[NSTask alloc] init];
    [refreshTask setLaunchPath:@"/Applications/Zebra.app/supersling"];
    NSArray *arguments = [[NSArray alloc] initWithObjects: @"apt-get", @"update", @"-o", @"Dir::Etc::SourceList=/var/lib/zebra/sources.list", @"-o", @"Dir::State::Lists=/var/lib/zebra/lists", @"-o", @"Dir::Etc::SourceParts=/var/lib/zebra/lists/partial/false", nil];
    [refreshTask setArguments:arguments];
    
    [refreshTask launch];
    [refreshTask waitUntilExit];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"zebra.db"];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSArray *bill = [self billOfReposToUpdate];
    for (ZBRepo *repo in bill) {
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @1, @"message": [NSString stringWithFormat:@"Parsing %@\n", [repo baseFileName]]}];
        NSString *release = [NSString stringWithFormat:@"/var/lib/zebra/lists/%@_Release", [repo baseFileName]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:release]) {
            release = [NSString stringWithFormat:@"/var/lib/zebra/lists/%@_main_binary-iphoneos-arm_Release", [repo baseFileName]]; //Do some funky package file with the default repos
        }
        NSLog(@"[Zebra] Repo: %@ %d", release, [repo repoID]);
        updateRepoInDatabase([release UTF8String], database, [repo repoID]);
            
        NSString *baseFileName = [release stringByReplacingOccurrencesOfString:@"_Release" withString:@""];
        NSString *packageFile = [NSString stringWithFormat:@"%@_Packages", baseFileName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:packageFile]) {
            packageFile = [NSString stringWithFormat:@"%@_main_binary-iphoneos-arm_Packages", baseFileName]; //Do some funky package file with the default repos
        }
        NSLog(@"[Zebra] Repo: %@ %d", packageFile, [repo repoID]);
        updatePackagesInDatabase([packageFile UTF8String], database, [repo repoID]);
    }
    
    NSLog(@"[Zebra] Populating installed database");
    
    NSDate *newUpdateDate = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:newUpdateDate forKey:@"lastUpdatedDate"];

    completion(true);
}

//Get number of packages in the database for each repo
- (int)numberOfPackagesInRepo:(int)repoID {
    int numberOfPackages = 0;
    
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM PACKAGES WHERE REPOID = %d GROUP BY PACKAGE", repoID];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"zebra.db"];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        numberOfPackages++;
    }
    sqlite3_close(database);
    
    return numberOfPackages;
}

//Gets paths of repo lists that need to be read from /var/lib/zebra/lists
- (NSArray <NSString *> *)managedSources {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *aptListDirectory = @"/var/lib/zebra/lists";
    NSArray *listOfFiles = [fileManager contentsOfDirectoryAtPath:aptListDirectory error:nil];
    NSMutableArray *managedSources = [[NSMutableArray alloc] init];
    
    for (NSString *path in listOfFiles) {
        if (([path rangeOfString:@"Release"].location != NSNotFound) && ([path rangeOfString:@".gpg"].location == NSNotFound)) {
            NSString *fullPath = [NSString stringWithFormat:@"/var/lib/zebra/lists/%@", path];
            [managedSources addObject:fullPath];
        }
    }
    
    return managedSources;
}

- (NSArray <ZBRepo *> *)sources {
    NSMutableArray *sources = [NSMutableArray new];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"zebra.db"];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *query = @"SELECT * FROM REPOS ORDER BY ORIGIN ASC";
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

    return (NSArray*)sources;
}

- (NSArray <ZBPackage *> *)packagesFromRepo:(int)repoID numberOfPackages:(int)limit startingAt:(int)start {
    NSMutableArray *packages = [NSMutableArray new];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"zebra.db"];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE REPOID = %d ORDER BY NAME ASC LIMIT %d OFFSET %d", repoID, limit, start];
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
    
    return (NSArray *)[self cleanUpDuplicatePackages:packages];
}

- (NSArray <ZBPackage *> *)installedPackages {
    NSMutableArray *installedPackages = [NSMutableArray new];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"zebra.db"];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *query = @"SELECT * FROM PACKAGES WHERE REPOID = 0 ORDER BY NAME ASC";
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
    
    return (NSArray*)installedPackages;
}

- (NSArray <ZBPackage *> *)searchForPackageName:(NSString *)name numberOfResults:(int)results {
    NSMutableArray *searchResults = [NSMutableArray new];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"zebra.db"];
    
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
    
    return searchResults;
}

- (NSArray <ZBRepo *> *)billOfReposToUpdate {
    NSMutableArray *bill = [NSMutableArray new];
    
    for (ZBRepo *repo in [self sources]) {
        BOOL needsUpdate = false;
        NSString *aptPackagesFile = [NSString stringWithFormat:@"/var/lib/zebra/lists/%@_Packages", [repo baseFileName]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:aptPackagesFile]) {
            aptPackagesFile = [NSString stringWithFormat:@"/var/lib/zebra/lists/%@_main_binary-iphoneos-arm_Packages", [repo baseFileName]]; //Do some funky package file with the default repos
        }
        
        NSString *cachedPackagesFile = [NSString stringWithFormat:@"/var/mobile/Library/Caches/xyz.willy.Zebra/lists/%@_Packages", [repo baseFileName]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
            cachedPackagesFile = [NSString stringWithFormat:@"/var/mobile/Library/Caches/xyz.willy.Zebra/lists/%@_main_binary-iphoneos-arm_Packages", [repo baseFileName]]; //Do some funky package file with the default repos
            if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
                NSLog(@"[Zebra] There is no cache file for %@ so it needs an update", [repo origin]);
                needsUpdate = true; //There isn't a cache for this so we need to parse it
            }
        }
        
        if (!needsUpdate) {
            FILE *aptFile = fopen([aptPackagesFile UTF8String], "r");
            FILE *cachedFile = fopen([cachedPackagesFile UTF8String], "r");
            needsUpdate = packages_file_changed(aptFile, cachedFile);
        }
        
        if (needsUpdate) {
            [bill addObject:repo];
        }
    }
    
    if ([bill count] > 0) {
        NSLog(@"[Zebra] Bill of Repositories that require an update: %@", bill);
    }
    else {
        NSLog(@"[Zebra] No repositories need an update");
    }
    
    
    return (NSArray *)bill;
}

- (void)deleteRepo:(ZBRepo *)repo {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"zebra.db"];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *query = @"DELETE FROM PACKAGES WHERE REPOID = ?; DELETE FROM REPOS WHERE REPOID = ?;";
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, 0) == SQLITE_OK) {
        sqlite3_bind_int(statement, 1, [repo repoID]);
        sqlite3_bind_int(statement, 2, [repo repoID]);
        sqlite3_step(statement);
    }
    
    sqlite3_close(database);
}

- (void)updateEssentials:(void (^)(BOOL success, NSArray *updates, BOOL hasUpdates))completion {
    [self fullLocalImport:^(BOOL installedSuccess) {
        NSLog(@"Completed local import");
        if (installedSuccess) {
            NSLog(@"getting update packages");
            [self getPackagesThatNeedUpdates:^(NSArray <ZBPackage *> *updateObjects, BOOL has) {
                if (has) {
                    NSLog(@"[Zebra] Has %d Updates!", (int)[updateObjects count]);
                }
                completion(true, updateObjects, has);
            }];
        }
    }];
}

- (void)getPackagesThatNeedUpdates:(void (^)(NSArray *updates, BOOL hasUpdates))completion {
    NSLog(@"pcakages need updates");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *updates = [NSMutableArray new];
        NSArray *installedPackages = [self installedPackages];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"zebra.db"];
        
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
        if (updates.count > 0) {
            completion(updates, true);
        }
        else {
            completion(NULL, false);
        }
    });
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

@end
