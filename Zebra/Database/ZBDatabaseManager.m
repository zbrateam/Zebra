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

@implementation ZBDatabaseManager

- (void)fullImport {
    //Refresh repos
    
    [self fullRemoteImport];
    [self fullLocalImport];
}

//Imports packages from repositories located in /var/lib/aupm/lists
- (void)fullRemoteImport {
#if TARGET_CPU_ARM
    NSArray *sourceLists = [self managedSources];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"aupm.db"];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    sqlite3_exec(database, "DELETE FROM REPOS", NULL, NULL, NULL);
    int i = 0;
    for (NSString *path in sourceLists) {
        importRepoToDatabase([path UTF8String], database, i);
        
        NSString *baseFileName = [path stringByReplacingOccurrencesOfString:@"_Release" withString:@""];
        NSString *packageFile = [NSString stringWithFormat:@"/var/lib/aupm/lists/%@_Packages", baseFileName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:packageFile]) {
            packageFile = [NSString stringWithFormat:@"/var/lib/aupm/lists/%@_main_binary-iphoneos-arm_Packages", baseFileName]; //Do some funky package file with the default repos
        }
        importPackagesToDatabase([packageFile UTF8String], database, i);
        i++;
    }
#else
    NSArray *sourceLists = @[[[NSBundle mainBundle] pathForResource:@"BigBoss" ofType:@"rel"]];
    NSString *packageFile = [[NSBundle mainBundle] pathForResource:@"BigBoss" ofType:@"pack"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"aupm.db"];
    NSLog(@"Database: %@", databasePath);
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    sqlite3_exec(database, "DELETE FROM REPOS; DELETE FROM PACKAGES", NULL, NULL, NULL);
    int i = 1;
    for (NSString *path in sourceLists) {
        importRepoToDatabase([path UTF8String], database, i);
        importPackagesToDatabase([packageFile UTF8String], database, i);
        i++;
    }
#endif
}

//Imports packages in /var/lib/dpkg/status into AUPM's database with a repoValue of '0' to indicate that the package is installed
- (void)fullLocalImport {
#if TARGET_OS_SIMULATOR //If the target is a simlator, load a demo list of installed packages
    NSString *installedPath = [[NSBundle mainBundle] pathForResource:@"Installed" ofType:@"pack"];
#else //Otherwise, load the actual file
    NSString *installedPath = @"/var/lib/dpkg/status";
#endif
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"aupm.db"];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    //We need to delete the entire list of installed packages
    
    char *sql = "DELETE FROM PACKAGES WHERE REPOID = 0";
    sqlite3_exec(database, sql, NULL, 0, NULL);
    importPackagesToDatabase([installedPath UTF8String], database, 0);
}

//Gets paths of repo lists that need to be read from /var/lib/aupm/lists
- (NSArray <NSString *> *)managedSources {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *aptListDirectory = @"/var/lib/aupm/lists";
    NSArray *listOfFiles = [fileManager contentsOfDirectoryAtPath:aptListDirectory error:nil];
    NSMutableArray *managedSources = [[NSMutableArray alloc] init];
    
    for (NSString *path in listOfFiles) {
        if (([path rangeOfString:@"Release"].location != NSNotFound) && ([path rangeOfString:@".gpg"].location == NSNotFound)) {
            NSString *fullPath = [NSString stringWithFormat:@"/var/lib/aupm/lists/%@", path];
            [managedSources addObject:fullPath];
        }
    }
    
    return managedSources;
}

- (NSArray <NSDictionary *> *)sources {
    NSMutableArray *sources = [NSMutableArray new];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"aupm.db"];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *query = @"SELECT * FROM REPOS";
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        const char *originChars = (const char *)sqlite3_column_text(statement, 0);
        const char *descriptionChars = (const char *)sqlite3_column_text(statement, 1);
        //        const char *versionChars = (const char *)sqlite3_column_text(statement, 4);
        //        const char *descriptionChars = (const char *)sqlite3_column_text(statement, 5);
        //        const char *sectionChars = (const char *)sqlite3_column_text(statement, 6);
        //        const char *depictionChars = (const char *)sqlite3_column_text(statement, 7);
        
        NSString *origin = [[NSString alloc] initWithUTF8String:originChars];
        NSString *description = [[NSString alloc] initWithUTF8String:descriptionChars];
        //        NSString *version = [[NSString alloc] initWithUTF8String:versionChars];
        //        NSString *section = [[NSString alloc] initWithUTF8String:sectionChars];
        //        NSString *description = [[NSString alloc] initWithUTF8String:descriptionChars];
        //        NSString *depictionURL;
        //        if (depictionChars == NULL) {
        //            depictionURL = NULL;
        //        }
        //        else {
        //            depictionURL = [[NSString alloc] initWithUTF8String:depictionChars];
        //        }
        
        //NSLog(@"%@: %@", packageID, packageName);
        NSMutableDictionary *source = [NSMutableDictionary new];
        [source setObject:origin forKey:@"origin"];
        [source setObject:description forKey:@"description"];
        [sources addObject:source];
    }
    sqlite3_finalize(statement);
    
    NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"origin" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];
    
    return (NSArray*)[sources sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray <NSDictionary *> *)packagesForRepo:(int)repoID {
    NSMutableArray *installedPackages = [NSMutableArray new];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"aupm.db"];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE REPOID = %d", repoID];
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        const char *packageIDChars = (const char *)sqlite3_column_text(statement, 0);
        const char *packageNameChars = (const char *)sqlite3_column_text(statement, 1);
        //        const char *versionChars = (const char *)sqlite3_column_text(statement, 4);
        //        const char *descriptionChars = (const char *)sqlite3_column_text(statement, 5);
        //        const char *sectionChars = (const char *)sqlite3_column_text(statement, 6);
        //        const char *depictionChars = (const char *)sqlite3_column_text(statement, 7);
        
        NSString *packageID = [[NSString alloc] initWithUTF8String:packageIDChars];
        NSString *packageName = [[NSString alloc] initWithUTF8String:packageNameChars];
        //        NSString *version = [[NSString alloc] initWithUTF8String:versionChars];
        //        NSString *section = [[NSString alloc] initWithUTF8String:sectionChars];
        //        NSString *description = [[NSString alloc] initWithUTF8String:descriptionChars];
        //        NSString *depictionURL;
        //        if (depictionChars == NULL) {
        //            depictionURL = NULL;
        //        }
        //        else {
        //            depictionURL = [[NSString alloc] initWithUTF8String:depictionChars];
        //        }
        
        //NSLog(@"%@: %@", packageID, packageName);
        NSMutableDictionary *package = [NSMutableDictionary new];
        if (packageName == NULL) {
            packageName = packageID;
        }
        
        [package setObject:packageName forKey:@"name"];
        [package setObject:packageID forKey:@"id"];
        [installedPackages addObject:package];
    }
    sqlite3_finalize(statement);
    
    NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];
    
    return (NSArray*)[installedPackages sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray <NSDictionary *> *)installedPackages {
    NSMutableArray *installedPackages = [NSMutableArray new];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"aupm.db"];
    
    sqlite3 *database;
    sqlite3_open([databasePath UTF8String], &database);
    
    NSString *query = @"SELECT * FROM PACKAGES WHERE REPOID = 0";
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        const char *packageIDChars = (const char *)sqlite3_column_text(statement, 0);
        const char *packageNameChars = (const char *)sqlite3_column_text(statement, 1);
//        const char *versionChars = (const char *)sqlite3_column_text(statement, 4);
//        const char *descriptionChars = (const char *)sqlite3_column_text(statement, 5);
//        const char *sectionChars = (const char *)sqlite3_column_text(statement, 6);
//        const char *depictionChars = (const char *)sqlite3_column_text(statement, 7);
        
        NSString *packageID = [[NSString alloc] initWithUTF8String:packageIDChars];
        NSString *packageName = [[NSString alloc] initWithUTF8String:packageNameChars];
//        NSString *version = [[NSString alloc] initWithUTF8String:versionChars];
//        NSString *section = [[NSString alloc] initWithUTF8String:sectionChars];
//        NSString *description = [[NSString alloc] initWithUTF8String:descriptionChars];
//        NSString *depictionURL;
//        if (depictionChars == NULL) {
//            depictionURL = NULL;
//        }
//        else {
//            depictionURL = [[NSString alloc] initWithUTF8String:depictionChars];
//        }
        
        //NSLog(@"%@: %@", packageID, packageName);
        NSMutableDictionary *package = [NSMutableDictionary new];
        if (packageName == NULL) {
            NSLog(@"package name: %@", packageName);
            packageName = packageID;
        }
        
        [package setObject:packageName forKey:@"name"];
        [package setObject:packageID forKey:@"id"];
        [installedPackages addObject:package];
    }
    sqlite3_finalize(statement);
    
    NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];
    
    return (NSArray*)[installedPackages sortedArrayUsingDescriptors:sortDescriptors];
}

@end
