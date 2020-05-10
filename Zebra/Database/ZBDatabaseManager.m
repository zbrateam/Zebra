//
//  ZBDatabaseManager.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@import FirebaseCrashlytics;

#import "ZBDatabaseManager.h"
#import "ZBDependencyResolver.h"

#import <ZBLog.h>
#import <ZBDevice.h>
#import <ZBSettings.h>
#import <Parsel/parsel.h>
#import <Parsel/vercmp.h>
#import <ZBAppDelegate.h>
#import <Sources/Helpers/ZBBaseSource.h>
#import <Sources/Helpers/ZBSource.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Downloads/ZBDownloadManager.h>
#import <Database/ZBColumn.h>
#import <Queue/ZBQueue.h>
#import <Packages/Helpers/ZBProxyPackage.h>

@interface ZBDatabaseManager () {
    int numberOfDatabaseUsers;
    int numberOfUpdates;
    NSMutableArray *completedSources;
    NSMutableArray *installedPackageIDs;
    NSMutableArray *upgradePackageIDs;
    BOOL databaseBeingUpdated;
    BOOL haltDatabaseOperations;
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
        instance.databaseDelegates = [NSMutableArray new];
    });
    return instance;
}

+ (BOOL)needsMigration {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[ZBAppDelegate databaseLocation]]) {
        return YES;
    }
    
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    [databaseManager openDatabase];
    
    // Checks to see if any of the databases have differing schemes and sets to update them if need be.
    BOOL migration = (needsMigration(databaseManager.database, 0) != 0 || needsMigration(databaseManager.database, 1) != 0 || needsMigration(databaseManager.database, 2) != 0);
    
    [databaseManager closeDatabase];
    
    return migration;
}

+ (NSDate *)lastUpdated {
    NSDate *lastUpdatedDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:@"lastUpdatedDate"];
    return lastUpdatedDate != NULL ? lastUpdatedDate : [NSDate distantPast];
}

+ (struct ZBBaseSource)baseSourceStructFromSource:(ZBBaseSource *)source {
    struct ZBBaseSource sourceStruct;
    sourceStruct.archiveType = [source.archiveType UTF8String];
    sourceStruct.repositoryURI = [source.repositoryURI UTF8String];
    sourceStruct.distribution = [source.distribution UTF8String];
    sourceStruct.components = [[[source components] componentsJoinedByString:@" "] UTF8String];
    sourceStruct.baseFilename = [source.baseFilename UTF8String];
    
    return sourceStruct;
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
    if (![self isDatabaseOpen] || !database) {
        assert(sqlite3_threadsafe());
        int result = sqlite3_open_v2([[ZBAppDelegate databaseLocation] UTF8String], &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_CREATE, NULL);
        if (result == SQLITE_OK) {
            [self increment];
        }
        return result;
    } else {
        [self increment];
        return SQLITE_OK;
    }
}

- (void)increment {
    @synchronized(self) {
        ++numberOfDatabaseUsers;
    }
}

- (void)decrement {
    @synchronized(self) {
        --numberOfDatabaseUsers;
    }
}

- (int)closeDatabase {
    @synchronized(self) {
        if (numberOfDatabaseUsers == 0) {
            return SQLITE_ERROR;
        }
    }
    
    if (--numberOfDatabaseUsers == 0 && [self isDatabaseOpen]) {
        int result = sqlite3_close(database);
        database = NULL;
        return result;
    }
    return SQLITE_OK;
}

- (BOOL)isDatabaseBeingUpdated {
    return databaseBeingUpdated;
}

- (void)setDatabaseBeingUpdated:(BOOL)updated {
    databaseBeingUpdated = updated;
}

- (BOOL)isDatabaseOpen {
    @synchronized(self) {
        return numberOfDatabaseUsers > 0 || database != NULL;
    }
}

- (void)printDatabaseError {
    databaseBeingUpdated = NO;
    const char *error = sqlite3_errmsg(database);
    if (error) {
        [[FIRCrashlytics crashlytics] logWithFormat:@"Database Error: %s", error];
        NSLog(@"[Zebra] Database Error: %s", error);
    }
}

- (void)addDatabaseDelegate:(id <ZBDatabaseDelegate>)delegate {
    if (![self.databaseDelegates containsObject:delegate]) {
        [self.databaseDelegates addObject:delegate];
    }
}

- (void)removeDatabaseDelegate:(id <ZBDatabaseDelegate>)delegate {
    [self.databaseDelegates removeObject:delegate];
}

- (void)bulkDatabaseStartedUpdate {
    for (int i = 0; i < self.databaseDelegates.count; ++i) {
        id <ZBDatabaseDelegate> delegate = self.databaseDelegates[i];
        [delegate databaseStartedUpdate];
    }
}

- (void)bulkDatabaseCompletedUpdate:(int)updates {
    databaseBeingUpdated = NO;
    for (int i = 0; i < self.databaseDelegates.count; ++i) {
        id <ZBDatabaseDelegate> delegate = self.databaseDelegates[i];
        [delegate databaseCompletedUpdate:updates];
    }
}

- (void)bulkPostStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    for (int i = 0; i < self.databaseDelegates.count; ++i) {
        id <ZBDatabaseDelegate> delegate = self.databaseDelegates[i];
        if ([delegate respondsToSelector:@selector(postStatusUpdate:atLevel:)]) {
            [delegate postStatusUpdate:status atLevel:level];
        }
    }
}

- (void)bulkSetSource:(NSString *)bfn busy:(BOOL)busy {
    for (int i = 0; i < self.databaseDelegates.count; ++i) {
        id <ZBDatabaseDelegate> delegate = self.databaseDelegates[i];
        if ([delegate respondsToSelector:@selector(setSource:busy:)]) {
            [delegate setSource:bfn busy:busy];
        }
    }
}

#pragma mark - Populating the database

- (void)updateDatabaseUsingCaching:(BOOL)useCaching userRequested:(BOOL)requested {
    if (databaseBeingUpdated)
        return;
    databaseBeingUpdated = YES;
    
    BOOL needsUpdate = NO;
    if (requested && haltDatabaseOperations) { //Halt database operations may need to be rethought
        [self setHaltDatabaseOperations:NO];
    }
    
    if (!requested && [ZBSettings wantsAutoRefresh]) {
        NSDate *currentDate = [NSDate date];
        NSDate *lastUpdatedDate = [ZBDatabaseManager lastUpdated];

        if (lastUpdatedDate != NULL) {
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags fromDate:lastUpdatedDate toDate:currentDate options:0];

            needsUpdate = ([components minute] >= 30);
        } else {
            needsUpdate = YES;
        }
    }
    
    if (requested || needsUpdate) {
        [self bulkDatabaseStartedUpdate];
        
        NSError *readError = NULL;
        NSSet <ZBBaseSource *> *baseSources = [ZBBaseSource baseSourcesFromList:[ZBAppDelegate sourcesListURL] error:&readError];
        if (readError) {
            //oh no!
            return;
        }
        
        [self bulkPostStatusUpdate:NSLocalizedString(@"Updating Sources", @"") atLevel:ZBLogLevelInfo];
        [self bulkPostStatusUpdate:[NSString stringWithFormat:NSLocalizedString(@"A total of %d files will be downloaded", @""), [baseSources count] * 2] atLevel:ZBLogLevelDescript];
        [self updateSources:baseSources useCaching:useCaching];
    } else {
        [self importLocalPackagesAndCheckForUpdates:YES sender:self];
    }
}

- (void)updateSource:(ZBBaseSource *)source useCaching:(BOOL)useCaching {
    [self updateSources:[NSSet setWithArray:@[source]] useCaching:useCaching];
}

- (void)updateSources:(NSSet <ZBBaseSource *> *)sources useCaching:(BOOL)useCaching {
    [self bulkDatabaseStartedUpdate];
    if (!self.downloadManager) {
        self.downloadManager = [[ZBDownloadManager alloc] initWithDownloadDelegate:self];
    }
    
    [self bulkPostStatusUpdate:NSLocalizedString(@"Starting Download", @"") atLevel:ZBLogLevelInfo];
    [self.downloadManager downloadSources:sources useCaching:useCaching];
}

- (void)setHaltDatabaseOperations:(BOOL)halt {
    haltDatabaseOperations = halt;
}

- (void)parseSources:(NSArray <ZBBaseSource *> *)sources {
    NSLog(@"Parsing Sources");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"disableCancelRefresh" object:nil];
    if (haltDatabaseOperations) {
        [[FIRCrashlytics crashlytics] logWithFormat:@"Database operations halted."];
        NSLog(@"[Zebra] Database operations halted");
        [self bulkDatabaseCompletedUpdate:numberOfUpdates];
        return;
    }
    [self bulkPostStatusUpdate:NSLocalizedString(@"Download Completed", @"") atLevel:ZBLogLevelInfo];
    self.downloadManager = nil;
    
    if ([self openDatabase] == SQLITE_OK) {
        createTable(database, 0);
        createTable(database, 1);
        sqlite3_exec(database, "CREATE TABLE PACKAGES_SNAPSHOT AS SELECT PACKAGE, VERSION, REPOID, LASTSEEN FROM PACKAGES WHERE REPOID > 0;", NULL, 0, NULL);
        sqlite3_exec(database, "CREATE INDEX tag_PACKAGEVERSION_SNAPSHOT ON PACKAGES_SNAPSHOT (PACKAGE, VERSION);", NULL, 0, NULL);
        sqlite3_int64 currentDate = (int)time(NULL);
        
//        dispatch_queue_t queue = dispatch_queue_create("xyz.willy.Zebra.repoParsing", NULL);
        for (ZBBaseSource *source in sources) {
//            dispatch_async(queue, ^{
                [self bulkSetSource:[source baseFilename] busy:YES];
                [self bulkPostStatusUpdate:[NSString stringWithFormat:NSLocalizedString(@"Parsing %@", @""), [source repositoryURI]] atLevel:ZBLogLevelDescript];
                
                //Deal with the source first
                int sourceID = [self sourceIDFromBaseFileName:[source baseFilename]];
                if (!source.releaseFilePath && source.packagesFilePath) { //We need to create a dummy source (for sources with no Release file)
                    if (sourceID == -1) {
                        sourceID = [self nextSourceID];
                        createDummySource([ZBDatabaseManager baseSourceStructFromSource:source], self->database, sourceID);
                    }
                }
                else if (source.releaseFilePath) {
                    if (sourceID == -1) { // Source does not exist in database, create it.
                        sourceID = [self nextSourceID];
                        if (importSourceToDatabase([ZBDatabaseManager baseSourceStructFromSource:source], [source.releaseFilePath UTF8String], self->database, sourceID) != PARSEL_OK) {
                            [self bulkPostStatusUpdate:[NSString stringWithFormat:@"%@ %@\n", NSLocalizedString(@"Error while opening file:", @""), source.releaseFilePath] atLevel:ZBLogLevelError];
                        }
                    } else {
                        if (updateSourceInDatabase([ZBDatabaseManager baseSourceStructFromSource:source], [source.releaseFilePath UTF8String], self->database, sourceID) != PARSEL_OK) {
                            [self bulkPostStatusUpdate:[NSString stringWithFormat:@"%@ %@\n", NSLocalizedString(@"Error while opening file:", @""), source.releaseFilePath] atLevel:ZBLogLevelError];
                        }
                    }
                    
                    if ([source.repositoryURI hasPrefix:@"https"]) {
                        NSURL *url = [NSURL URLWithString:[source.repositoryURI stringByAppendingPathComponent:@"payment_endpoint"]];

                        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                            NSString *endpoint = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            if ([endpoint length] != 0 && (long)[httpResponse statusCode] == 200) {
                                if ([endpoint hasPrefix:@"https"]) {
                                    [self bulkPostStatusUpdate:[NSString stringWithFormat:NSLocalizedString(@"Adding Payment Vendor URL for %@", @""), source.repositoryURI] atLevel:ZBLogLevelDescript];
                                    if ([self openDatabase] == SQLITE_OK) {
                                        addPaymentEndpointForSource([endpoint UTF8String], self->database, sourceID);
                                        [self closeDatabase];
                                    }
                                }
                            }
                        }];

                        [task resume];
                    }
                }
                
                //Deal with the packages
                if (source.packagesFilePath && updatePackagesInDatabase([source.packagesFilePath UTF8String], self->database, sourceID, currentDate) != PARSEL_OK) {
                    [self bulkPostStatusUpdate:[NSString stringWithFormat:@"%@ %@\n", NSLocalizedString(@"Error while opening file:", @""), source.packagesFilePath] atLevel:ZBLogLevelError];
                }
                
                [self bulkSetSource:[source baseFilename] busy:NO];
//            });
        }
        
        sqlite3_exec(database, "DROP TABLE PACKAGES_SNAPSHOT;", NULL, 0, NULL);
        
        [self bulkPostStatusUpdate:NSLocalizedString(@"Done", @"") atLevel:ZBLogLevelInfo];
        
        [self importLocalPackagesAndCheckForUpdates:YES sender:self];
        [self updateLastUpdated];
        [self bulkDatabaseCompletedUpdate:numberOfUpdates];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
        [self closeDatabase];
    } else {
        [self printDatabaseError];
    }
}

- (void)importLocalPackagesAndCheckForUpdates:(BOOL)checkForUpdates sender:(id)sender {
    if (haltDatabaseOperations) {
        NSLog(@"[Zebra] Database operations halted");
        return;
    }
    
    BOOL needsDelegateStart = !([sender isKindOfClass:[ZBDatabaseManager class]]);
    if (needsDelegateStart) {
        [self bulkDatabaseStartedUpdate];
    }
    NSLog(@"[Zebra] Importing local packages");
    [self importLocalPackages];
    if (checkForUpdates) {
        [self checkForPackageUpdates];
    }
    if (needsDelegateStart) {
        [self bulkDatabaseCompletedUpdate:numberOfUpdates];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
    databaseBeingUpdated = NO;
}

- (void)importLocalPackages {
    if (haltDatabaseOperations) {
        NSLog(@"[Zebra] Database operations halted");
        return;
    }
    
    NSString *installedPath;
    if ([ZBDevice needsSimulation]) { // If the target is a simlator, load a demo list of installed packages
        installedPath = [[NSBundle mainBundle] pathForResource:@"Installed" ofType:@"pack"];
    } else { // Otherwise, load the actual file
        installedPath = @"/var/lib/dpkg/status";
    }
    
    if ([self openDatabase] == SQLITE_OK) {
        // Delete packages from local sources (-1 and 0)
        sqlite3_exec(database, "DELETE FROM PACKAGES WHERE REPOID = 0", NULL, 0, NULL);
        sqlite3_exec(database, "DELETE FROM PACKAGES WHERE REPOID = -1", NULL, 0, NULL);
        
        // Import packages from the installedPath
        importPackagesToDatabase([installedPath UTF8String], database, 0);
        
        [self closeDatabase];
    } else {
        [self printDatabaseError];
    }
}

- (void)checkForPackageUpdates {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *installedPackages = [NSMutableArray new];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT * FROM PACKAGES WHERE REPOID = 0;", -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                [installedPackages addObject:package];
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        // Check for updates
        NSLog(@"[Zebra] Checking for updates...");
        NSMutableArray *found = [NSMutableArray new];
        
        createTable(database, 2);
        
        numberOfUpdates = 0;
        upgradePackageIDs = [NSMutableArray new];
        for (ZBPackage *package in installedPackages) {
            if ([found containsObject:package.identifier]) {
                ZBLog(@"[Zebra] I already checked %@, skipping", package.identifier);
                continue;
            }
            
            ZBPackage *topPackage = [self topVersionForPackage:package];
            NSComparisonResult compare = [package compare:topPackage];
            if (compare == NSOrderedAscending) {
                ZBLog(@"[Zebra] Installed package %@ is less than top package %@, it needs an update", package, topPackage);
                
                BOOL ignoreUpdates = [topPackage ignoreUpdates];
                if (!ignoreUpdates) ++numberOfUpdates;
                NSString *query = [NSString stringWithFormat:@"REPLACE INTO UPDATES(PACKAGE, VERSION, IGNORE) VALUES(\'%@\', \'%@\', %d);", [topPackage identifier], [topPackage version], ignoreUpdates ? 1 : 0];
                
                if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                        break;
                    }
                } else {
                    [self printDatabaseError];
                }
                sqlite3_finalize(statement);
                
                [upgradePackageIDs addObject:[topPackage identifier]];
            } else if (compare == NSOrderedSame) {
                NSString *query;
                BOOL packageIgnoreUpdates = [package ignoreUpdates];
                if (packageIgnoreUpdates)
                    // This package has no update and the user actively ignores updates from it, we update the latest version here
                    query = [NSString stringWithFormat:@"REPLACE INTO UPDATES(PACKAGE, VERSION, IGNORE) VALUES(\'%@\', \'%@\', 1);", package.identifier, package.version];
                else
                    // This package has no update and the user does not ignore updates from it, having the record in the database is waste of space
                    query = [NSString stringWithFormat:@"DELETE FROM UPDATES WHERE PACKAGE = \'%@\';", package.identifier];
                if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                        break;
                    }
                } else {
                    [self printDatabaseError];
                }
                sqlite3_finalize(statement);
            }
            [found addObject:package.identifier];
        }
        
        //In order to make this easy, we're going to check for "Essential" packages that aren't installed and mark them as updates
        NSMutableArray *essentials = [NSMutableArray new];
        sqlite3_stmt *essentialStatement; //v important statement
        if (sqlite3_prepare_v2(database, "SELECT PACKAGE, VERSION FROM PACKAGES WHERE REPOID > 0 AND ESSENTIAL = \'yes\' COLLATE NOCASE", -1, &essentialStatement, nil) == SQLITE_OK) {
            while (sqlite3_step(essentialStatement) == SQLITE_ROW) {
                const char *identifierChars = (const char *)sqlite3_column_text(essentialStatement, 0);
                const char *versionChars = (const char *)sqlite3_column_text(essentialStatement, 1);
                
                NSString *packageIdentifier = [NSString stringWithUTF8String:identifierChars];
                NSString *version = [NSString stringWithUTF8String:versionChars];
                
                if (![self packageIDIsInstalled:packageIdentifier version:NULL]) {
                    NSDictionary *essentialPackage = @{@"id": packageIdentifier, @"version": version};
                    [essentials addObject:essentialPackage];
                }
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(essentialStatement);
        
        for (NSDictionary *essentialPackage in essentials) {
            NSString *identifier = [essentialPackage objectForKey:@"id"];
            NSString *version = [essentialPackage objectForKey:@"version"];
            
            BOOL ignoreUpdates = [self areUpdatesIgnoredForPackageIdentifier:[essentialPackage objectForKey:@"id"]];
            if (!ignoreUpdates) ++numberOfUpdates;
            
            if (sqlite3_prepare_v2(database, "REPLACE INTO UPDATES(PACKAGE, VERSION, IGNORE) VALUES(?, ?, ?);", -1, &statement, nil) == SQLITE_OK) {
                sqlite3_bind_text(statement, 1, [identifier UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(statement, 2, [version UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_int(statement, 3, ignoreUpdates ? 1 : 0);
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    break;
                }
            } else {
                [self printDatabaseError];
            }
            sqlite3_finalize(statement);
            
            [upgradePackageIDs addObject:identifier];
        }
        
        [self closeDatabase];
    } else {
        [self printDatabaseError];
    }
}

- (void)dropTables {
    if ([self openDatabase] == SQLITE_OK) {
        sqlite3_exec(database, "DROP TABLE PACKAGES;", NULL, 0, NULL);
        sqlite3_exec(database, "DROP TABLE REPOS;", NULL, 0, NULL);
        
        // Update UPDATES table schema while retaining user data
        sqlite3_exec(database, "DELETE FROM UPDATES WHERE IGNORE != 1;", NULL, 0, NULL);
        sqlite3_exec(database, "CREATE TABLE UPDATES_SNAPSHOT AS SELECT PACKAGE, VERSION, IGNORE FROM UPDATES;", NULL, 0, NULL);
        sqlite3_exec(database, "DROP TABLE UPDATES;", NULL, 0, NULL);
        createTable(database, 2);
        sqlite3_exec(database, "INSERT INTO UPDATES SELECT PACKAGE, VERSION, IGNORE FROM UPDATES_SNAPSHOT;", NULL, 0, NULL);
        sqlite3_exec(database, "DROP TABLE UPDATES_SNAPSHOT;", NULL, 0, NULL);
        
        [self closeDatabase];
    } else {
        [self printDatabaseError];
    }
}

- (void)updateLastUpdated {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastUpdatedDate"];
}

#pragma mark - Source management

- (int)sourceIDFromBaseFileName:(NSString *)bfn {
    if ([self openDatabase] == SQLITE_OK) {
        sqlite3_stmt *statement = NULL;
        int sourceID = -1;
        if (sqlite3_prepare_v2(database, "SELECT REPOID FROM REPOS WHERE BASEFILENAME = ?", -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [bfn UTF8String], -1, SQLITE_TRANSIENT);
            while (sqlite3_step(statement) == SQLITE_ROW) {
                sourceID = sqlite3_column_int(statement, 0);
                break;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return sourceID;
    } else {
        [self printDatabaseError];
    }
    return -1;
}

- (int)sourceIDFromBaseURL:(NSString *)baseURL strict:(BOOL)strict {
    if ([self openDatabase] == SQLITE_OK) {
        sqlite3_stmt *statement = NULL;
        int sourceID = -1;
        if (sqlite3_prepare_v2(database, strict ? "SELECT REPOID FROM REPOS WHERE URI = ?" : "SELECT REPOID FROM REPOS WHERE URI LIKE ?", -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, strict ? [baseURL UTF8String] : [[NSString stringWithFormat:@"%%%@%%", baseURL] UTF8String], -1, SQLITE_TRANSIENT);
            while (sqlite3_step(statement) == SQLITE_ROW) {
                sourceID = sqlite3_column_int(statement, 0);
                break;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return sourceID;
    } else {
        [self printDatabaseError];
    }
    return -1;
}

- (ZBSource * _Nullable)sourceFromBaseURL:(NSString *)burl {
    NSRange dividerRange = [burl rangeOfString:@"://"];
    NSUInteger divide = NSMaxRange(dividerRange);
    NSString *baseURL = divide > [burl length] ? burl : [burl substringFromIndex:divide];
    
    if ([self openDatabase] == SQLITE_OK) {
        sqlite3_stmt *statement = NULL;
        ZBSource *source = nil;
        if (sqlite3_prepare_v2(database, "SELECT * FROM REPOS WHERE BASEURL = ?", -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [baseURL UTF8String], -1, SQLITE_TRANSIENT);
            while (sqlite3_step(statement) == SQLITE_ROW) {
                source = [[ZBSource alloc] initWithSQLiteStatement:statement];
                break;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return source;
    } else {
        [self printDatabaseError];
    }
    return nil;
}

- (ZBSource * _Nullable)sourceFromBaseFilename:(NSString *)baseFilename {
    if ([self openDatabase] == SQLITE_OK) {
        sqlite3_stmt *statement = NULL;
        ZBSource *source = nil;
        if (sqlite3_prepare_v2(database, "SELECT * FROM REPOS WHERE BASEFILENAME = ?", -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [baseFilename UTF8String], -1, SQLITE_TRANSIENT);
            while (sqlite3_step(statement) == SQLITE_ROW) {
                source = [[ZBSource alloc] initWithSQLiteStatement:statement];
                break;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return source;
    } else {
        [self printDatabaseError];
    }
    return nil;
}

- (int)nextSourceID {
    if ([self openDatabase] == SQLITE_OK) {
        sqlite3_stmt *statement = NULL;
        int sourceID = 0;
        if (sqlite3_prepare_v2(database, "SELECT REPOID FROM REPOS ORDER BY REPOID DESC LIMIT 1", -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                sourceID = sqlite3_column_int(statement, 0);
                break;
            }
        } else {
            [self printDatabaseError];
        }
        
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return sourceID + 1;
    } else {
        [self printDatabaseError];
    }
    return -1;
}

- (int)numberOfPackagesInSource:(ZBSource * _Nullable)source section:(NSString * _Nullable)section enableFiltering:(BOOL)enableFiltering {
    if ([self openDatabase] == SQLITE_OK) {
        // FIXME: Use NSUserDefaults, variables binding
        int packages = 0;
        NSString *query = nil;
        NSString *sourcePart = source ? [NSString stringWithFormat:@"REPOID = %d", [source sourceID]] : @"REPOID > 0";
        if (section != NULL) {
            query = [NSString stringWithFormat:@"SELECT COUNT(distinct package) FROM PACKAGES WHERE SECTION = \'%@\' AND %@", section, sourcePart];
        } else {
            query = [NSString stringWithFormat:@"SELECT SECTION, AUTHORNAME, AUTHOREMAIL, REPOID FROM PACKAGES WHERE %@ GROUP BY PACKAGE", sourcePart];
        }
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                if (section == NULL) {
                    if (!enableFiltering) {
                        ++packages;
                    } else {
                        const char *packageSection = (const char *)sqlite3_column_text(statement, 1);
                        const char *packageAuthor = (const char *)sqlite3_column_text(statement, 2);
                        const char *packageAuthorEmail = (const char *)sqlite3_column_text(statement, 3);
                        if (packageSection != 0 && packageAuthor != 0 && packageAuthorEmail != 0) {
                            int sourceID = sqlite3_column_int(statement, 3);
                            if (![ZBSettings isSectionFiltered:[NSString stringWithUTF8String:packageSection] forSource:[ZBSource sourceMatchingSourceID:sourceID]] && ![ZBSettings isAuthorBlocked:[NSString stringWithUTF8String:packageAuthor] email:[NSString stringWithUTF8String:packageAuthorEmail]])
                                ++packages;
                        }
                        else {
                            ++packages; // We can't filter this package as it has no section or no author
                        }
                    }
                } else {
                    packages = sqlite3_column_int(statement, 0);
                    break;
                }
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return packages;
    } else {
        [self printDatabaseError];
    }
    return -1;
}

- (int)numberOfPackagesInSource:(ZBSource * _Nullable)source section:(NSString * _Nullable)section {
    return [self numberOfPackagesInSource:source section:section enableFiltering:NO];
}

- (NSSet <ZBSource *> *)sources {
    if ([self openDatabase] == SQLITE_OK) {
        NSError *readError = NULL;
        NSMutableSet *baseSources = [[ZBBaseSource baseSourcesFromList:[ZBAppDelegate sourcesListURL] error:&readError] mutableCopy];
        NSMutableSet *sources = [NSMutableSet new];

        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT * FROM REPOS", -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBSource *source = [[ZBSource alloc] initWithSQLiteStatement:statement];
                for (ZBBaseSource *baseSource in [baseSources copy]) {
                    if ([baseSource isEqual:source]) {
                        [sources addObject:source];
                        [baseSources removeObject:baseSource];
                        break;
                    }
                }
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];

        return [sources setByAddingObjectsFromSet:baseSources];
    }
    
    [self printDatabaseError];
    return NULL;
}

- (ZBSource *)sourceFromSourceID:(int)sourceID {
    if ([self openDatabase] == SQLITE_OK) {
        ZBSource *source;

        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT * FROM REPOS WHERE REPOID = ?", -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, sourceID);
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBSource *potential = [[ZBSource alloc] initWithSQLiteStatement:statement];
                if (potential) source = potential;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];

        return source;
    }
    
    [self printDatabaseError];
    return NULL;
}

- (NSSet <ZBSource *> * _Nullable)sourcesWithPaymentEndpoint {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableSet *sources = [NSMutableSet new];

        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT * FROM REPOS WHERE VENDOR NOT NULL;", -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBSource *source = [[ZBSource alloc] initWithSQLiteStatement:statement];
                
                [sources addObject:source];
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];

        return sources;
    }
    
    [self printDatabaseError];
    return NULL;
}

- (void)deleteSource:(ZBSource *)source {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *packageQuery = [NSString stringWithFormat:@"DELETE FROM PACKAGES WHERE REPOID = %d", [source sourceID]];
        NSString *sourceQuery = [NSString stringWithFormat:@"DELETE FROM REPOS WHERE REPOID = %d", [source sourceID]];
        
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
        sqlite3_exec(database, [packageQuery UTF8String], NULL, NULL, NULL);
        sqlite3_exec(database, [sourceQuery UTF8String], NULL, NULL, NULL);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
        
        [self closeDatabase];
    } else {
        [self printDatabaseError];
    }
}

- (void)cancelUpdates:(id <ZBDatabaseDelegate>)delegate {
    [self setDatabaseBeingUpdated:NO];
    [self setHaltDatabaseOperations:YES];
//    [self.downloadManager stopAllDownloads];
    [self bulkDatabaseCompletedUpdate:-1];
    [self removeDatabaseDelegate:delegate];
}

- (NSArray * _Nullable)sectionReadout {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *sections = [NSMutableArray new];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT SECTION from packages GROUP BY SECTION ORDER BY SECTION", -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *sectionChars = (const char *)sqlite3_column_text(statement, 0);
                if (sectionChars != 0) {
                    NSString *section = [[NSString stringWithUTF8String:sectionChars] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                    if (section) [sections addObject:section];
                }
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return sections;
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSDictionary * _Nullable)sectionReadoutForSource:(ZBSource *)source {
    if (![source respondsToSelector:@selector(sourceID)]) return NULL;
    
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableDictionary *sectionReadout = [NSMutableDictionary new];
        
        NSString *query = [NSString stringWithFormat:@"SELECT SECTION, COUNT(distinct package) as SECTION_COUNT from packages WHERE REPOID = %d GROUP BY SECTION ORDER BY SECTION", [source sourceID]];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *sectionChars = (const char *)sqlite3_column_text(statement, 0);
                if (sectionChars != 0) {
                    NSString *section = [[NSString stringWithUTF8String:sectionChars] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                    [sectionReadout setObject:[NSNumber numberWithInt:sqlite3_column_int(statement, 1)] forKey:section];
                }
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return sectionReadout;
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSURL * _Nullable)paymentVendorURLForSource:(ZBSource *)source {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT VENDOR FROM REPOS WHERE REPOID = %d", [source sourceID]];
        sqlite3_stmt *statement = NULL;
        
        NSString *vendorURL = nil;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            sqlite3_step(statement);
            
            const char *vendorChars = (const char *)sqlite3_column_text(statement, 0);
            vendorURL = vendorChars ? [NSString stringWithUTF8String:vendorChars] : NULL;
        }
        else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        if (vendorURL) {
            return [NSURL URLWithString:vendorURL];
        }
    }
    return NULL;
}

#pragma mark - Package management

- (NSArray <ZBPackage *> * _Nullable)packagesFromSource:(ZBSource * _Nullable)source inSection:(NSString * _Nullable)section numberOfPackages:(int)limit startingAt:(int)start enableFiltering:(BOOL)enableFiltering {
    
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *packages = [NSMutableArray new];
        NSString *query = nil;
        
        if (section == NULL) {
            NSString *sourcePart = source ? [NSString stringWithFormat:@"WHERE REPOID = %d", [source sourceID]] : @"WHERE REPOID > 0";
            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES %@ ORDER BY LASTSEEN DESC LIMIT %d OFFSET %d", sourcePart, limit, start];
        } else {
            NSString *sourcePart = source ? [NSString stringWithFormat:@"AND REPOID = %d", [source sourceID]] : @"AND REPOID > 0";
            
            NSString *sectionString;
            if ([section containsString:@" "]) {
                sectionString = [NSString stringWithFormat:@"SECTION = \'%@\' OR SECTION = \'%@\'", section, [section stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
            }
            else if ([section containsString:@"_"]) {
                sectionString = [NSString stringWithFormat:@"SECTION = \'%@\' OR SECTION = \'%@\'", section, [section stringByReplacingOccurrencesOfString:@"_" withString:@" "]];
            }
            else {
                sectionString = [NSString stringWithFormat:@"SECTION = \'%@\'", section];
            }
            
            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE %@ %@ LIMIT %d OFFSET %d", sectionString, sourcePart, limit, start];
        }
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                
                if (section == NULL && enableFiltering && [ZBSettings isPackageFiltered:package])
                    continue;
                
                [packages addObject:package];
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return [self cleanUpDuplicatePackages:packages];
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSArray <ZBPackage *> * _Nullable)packagesFromSource:(ZBSource * _Nullable)source inSection:(NSString * _Nullable)section numberOfPackages:(int)limit startingAt:(int)start {
    return [self packagesFromSource:source inSection:section numberOfPackages:limit startingAt:start enableFiltering:NO];
}

- (NSMutableArray <ZBPackage *> * _Nullable)installedPackages:(BOOL)includeVirtualDependencies {
    if ([self openDatabase] == SQLITE_OK) {
        installedPackageIDs = [NSMutableArray new];
        NSMutableArray *installedPackages = [NSMutableArray new];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, includeVirtualDependencies ? "SELECT * FROM PACKAGES WHERE REPOID < 1;" : "SELECT * FROM PACKAGES WHERE REPOID = 0;", -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *packageIDChars =        (const char *)sqlite3_column_text(statement, ZBPackageColumnPackage);
                const char *versionChars =          (const char *)sqlite3_column_text(statement, ZBPackageColumnVersion);
                NSString *packageID = [NSString stringWithUTF8String:packageIDChars];
                NSString *packageVersion = [NSString stringWithUTF8String:versionChars];
                ZBPackage *package = [self packageForID:packageID equalVersion:packageVersion];
                if (package) {
                    package.version = packageVersion;
                    [installedPackageIDs addObject:package.identifier];
                    [installedPackages addObject:package];
                }
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return installedPackages;
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSDictionary <NSString *, NSArray <NSDictionary *> *> *)installedPackagesList {
    NSMutableArray *installedPackages = [NSMutableArray new];
    NSMutableArray *virtualPackages = [NSMutableArray new];
    
    for (ZBPackage *package in [self installedPackages:YES]) {
        NSDictionary *installedPackage = @{@"identifier": [package identifier], @"version": [package version]};
        [installedPackages addObject:installedPackage];
        
        for (NSString *virtualPackageLine in [package provides]) {
            NSArray *comps = [ZBDependencyResolver separateVersionComparison:virtualPackageLine];
            NSDictionary *virtualPackage = @{@"identifier": comps[0], @"version": comps[2]};
            
            [virtualPackages addObject:virtualPackage];
        }
    }
    
    return @{@"installed": installedPackages, @"virtual": virtualPackages};
}

- (NSMutableArray <ZBPackage *> *)packagesWithIgnoredUpdates {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *packagesWithIgnoredUpdates = [NSMutableArray new];
        NSMutableArray *irrelevantPackages = [NSMutableArray new];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT * FROM UPDATES WHERE IGNORE = 1;", -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *identifierChars = (const char *)sqlite3_column_text(statement, ZBUpdateColumnID);
                const char *versionChars = (const char *)sqlite3_column_text(statement, ZBUpdateColumnVersion);
                NSString *identifier = [NSString stringWithUTF8String:identifierChars];
                ZBPackage *package = nil;
                if (versionChars != 0) {
                    NSString *version = [NSString stringWithUTF8String:versionChars];
                    
                    package = [self packageForID:identifier equalVersion:version];
                    if (package != NULL) {
                        [packagesWithIgnoredUpdates addObject:package];
                    }
                }
                if (![self packageIDIsInstalled:identifier version:nil]) {
                    // We don't need ignored updates from packages we don't have them installed
                    [irrelevantPackages addObject:[NSString stringWithFormat:@"'%@'", identifier]];
                    if (package) {
                        [packagesWithIgnoredUpdates removeObject:package];
                    }
                }
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        if (irrelevantPackages.count) {
            sqlite3_exec(database, [[NSString stringWithFormat:@"DELETE FROM UPDATES WHERE PACKAGE IN (%@)", [irrelevantPackages componentsJoinedByString:@", "]] UTF8String], NULL, 0, NULL);
        }
        
        [self closeDatabase];
        
        return packagesWithIgnoredUpdates;
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSMutableArray <ZBPackage *> * _Nullable)packagesWithUpdates {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *packagesWithUpdates = [NSMutableArray new];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT * FROM UPDATES WHERE IGNORE = 0;", -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *identifierChars = (const char *)sqlite3_column_text(statement, ZBUpdateColumnID);
                const char *versionChars = (const char *)sqlite3_column_text(statement, ZBUpdateColumnVersion);
                NSString *identifier = [NSString stringWithUTF8String:identifierChars];
                if (versionChars != 0) {
                    NSString *version = [NSString stringWithUTF8String:versionChars];
                    
                    ZBPackage *package = [self packageForID:identifier equalVersion:version];
                    if (package != NULL && [upgradePackageIDs containsObject:package.identifier]) {
                        [packagesWithUpdates addObject:package];
                    }
                } else if ([upgradePackageIDs containsObject:identifier]) {
                    [upgradePackageIDs removeObject:identifier];
                }
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return packagesWithUpdates;
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSArray * _Nullable)searchForPackageName:(NSString *)name fullSearch:(BOOL)fullSearch {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *searchResults = [NSMutableArray new];
        NSString *columns = fullSearch ? @"*" : @"PACKAGE, NAME, VERSION, REPOID, SECTION, ICONURL";
        NSString *limit = fullSearch ? @";" : @" LIMIT 30;";
        NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM PACKAGES WHERE NAME LIKE \'%%%@\%%\' AND REPOID > -1 ORDER BY (CASE WHEN NAME = \'%@\' THEN 1 WHEN NAME LIKE \'%@%%\' THEN 2 ELSE 3 END) COLLATE NOCASE%@", columns, name, name, name, limit];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                if (fullSearch) {
                    ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                    
                    [searchResults addObject:package];
                }
                else {
                    ZBProxyPackage *proxyPackage = [[ZBProxyPackage alloc] initWithSQLiteStatement:statement];
                    
                    const char *sectionChars = (const char *)sqlite3_column_text(statement, 4);
                    const char *iconURLChars = (const char *)sqlite3_column_text(statement, 5);
                    
                    NSString *section = sectionChars != 0 ? [NSString stringWithUTF8String:sectionChars] : NULL;
                    NSString *iconURLString = iconURLChars != 0 ? [NSString stringWithUTF8String:iconURLChars] : NULL;
                    NSURL *iconURL = [NSURL URLWithString:iconURLString];
                    
                    if (section) proxyPackage.section = section;
                    if (iconURL) proxyPackage.iconURL = iconURL;
                    
                    [searchResults addObject:proxyPackage];
                }
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return [self cleanUpDuplicatePackages:searchResults];
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSArray <NSArray <NSString *> *> * _Nullable)searchForAuthorName:(NSString *)authorName fullSearch:(BOOL)fullSearch {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *searchResults = [NSMutableArray new];
        NSString *limit = fullSearch ? @";" : @" LIMIT 30;";
        NSString *query = [NSString stringWithFormat:@"SELECT AUTHORNAME, AUTHOREMAIL FROM PACKAGES WHERE AUTHORNAME LIKE \'%%%@\%%\' AND REPOID > -1 GROUP BY AUTHORNAME ORDER BY (CASE WHEN AUTHORNAME = \'%@\' THEN 1 WHEN AUTHORNAME LIKE \'%@%%\' THEN 2 ELSE 3 END) COLLATE NOCASE%@", authorName, authorName, authorName, limit];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *authorChars = (const char *)sqlite3_column_text(statement, 0);
                const char *emailChars = (const char *)sqlite3_column_text(statement, 1);
                
                NSString *author = authorChars != 0 ? [NSString stringWithUTF8String:authorChars] : NULL;
                NSString *email = emailChars != 0 ? [NSString stringWithUTF8String:emailChars] : NULL;
                
                if (author || email) {
                    [searchResults addObject:@[author ?: email, email ?: author]];
                }
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return searchResults;
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSArray <NSString *> * _Nullable)searchForAuthorFromEmail:(NSString *)authorEmail fullSearch:(BOOL)fullSearch {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *searchResults = [NSMutableArray new];
        NSString *limit = fullSearch ? @";" : @" LIMIT 30;";
        NSString *query = [NSString stringWithFormat:@"SELECT AUTHORNAME, AUTHOREMAIL FROM PACKAGES WHERE AUTHOREMAIL = \'%@\' AND REPOID > -1 GROUP BY AUTHORNAME COLLATE NOCASE%@", authorEmail, limit];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *authorChars = (const char *)sqlite3_column_text(statement, 0);
                const char *emailChars = (const char *)sqlite3_column_text(statement, 1);
                
                NSString *author = authorChars != 0 ? [NSString stringWithUTF8String:authorChars] : NULL;
                NSString *email = emailChars != 0 ? [NSString stringWithUTF8String:emailChars] : NULL;
                
                if (author && email) {
                    [searchResults addObject:@[author, email]];
                }
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return searchResults;
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSArray <ZBPackage *> * _Nullable)packagesFromIdentifiers:(NSArray <NSString *> *)requestedPackages {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *packages = [NSMutableArray new];
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE IN ('\%@') ORDER BY NAME COLLATE NOCASE ASC", [requestedPackages componentsJoinedByString:@"','"]];
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [[requestedPackages componentsJoinedByString:@"','"] UTF8String], -1, SQLITE_TRANSIENT);
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                
                [packages addObject:package];
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        return [self cleanUpDuplicatePackages:packages];
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (ZBPackage * _Nullable)packageFromProxy:(ZBProxyPackage *)proxy {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE = \'%@\' AND VERSION = \'%@\' AND REPOID = %d LIMIT 1", proxy.identifier, proxy.version, proxy.sourceID];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            sqlite3_step(statement);
            
            ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
            sqlite3_finalize(statement);
            [self closeDatabase];
            
            return package;
        }
        else {
            [self printDatabaseError];
            sqlite3_finalize(statement);
            [self closeDatabase];
        }
    }
    else {
        [self printDatabaseError];
    }
    return NULL;
}

#pragma mark - Package status

- (BOOL)packageIDHasUpdate:(NSString *)packageIdentifier {
    if ([upgradePackageIDs count] != 0) {
        return [upgradePackageIDs containsObject:packageIdentifier];
    } else {
        if ([self openDatabase] == SQLITE_OK) {
            BOOL packageIsInstalled = NO;
            sqlite3_stmt *statement = NULL;
            if (sqlite3_prepare_v2(database, "SELECT PACKAGE FROM UPDATES WHERE PACKAGE = ? AND IGNORE = 0 LIMIT 1;", -1, &statement, nil) == SQLITE_OK) {
                sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    packageIsInstalled = YES;
                    break;
                }
            } else {
                [self printDatabaseError];
            }
            sqlite3_finalize(statement);
            [self closeDatabase];
            
            return packageIsInstalled;
        } else {
            [self printDatabaseError];
        }
        return NO;
    }
}

- (BOOL)packageHasUpdate:(ZBPackage *)package {
    return [self packageIDHasUpdate:package.identifier];
}

- (BOOL)packageIDIsInstalled:(NSString *)packageIdentifier version:(NSString *_Nullable)version {
    if (version == NULL && [installedPackageIDs count] != 0) {
        BOOL packageIsInstalled = [[installedPackageIDs copy] containsObject:packageIdentifier];
        ZBLog(@"[Zebra] [installedPackageIDs] Is %@ (version: %@) installed? : %d", packageIdentifier, version, packageIsInstalled);
        if (packageIsInstalled) {
            return packageIsInstalled;
        }
    }
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query;
        
        if (version != NULL) {
            query = [NSString stringWithFormat:@"SELECT PACKAGE FROM PACKAGES WHERE PACKAGE = \'%@\' AND VERSION = \'%@\' AND REPOID < 1 LIMIT 1;", packageIdentifier, version];
        } else {
            query = [NSString stringWithFormat:@"SELECT PACKAGE FROM PACKAGES WHERE PACKAGE = \'%@\' AND REPOID < 1 LIMIT 1;", packageIdentifier];
        }
        
        BOOL packageIsInstalled = NO;
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                packageIsInstalled = YES;
                break;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        ZBLog(@"[Zebra] Is %@ (version: %@) installed? : %d", packageIdentifier, version, packageIsInstalled);
        return packageIsInstalled;
    } else {
        [self printDatabaseError];
    }
    return NO;
}

- (BOOL)packageIsInstalled:(ZBPackage *)package versionStrict:(BOOL)strict {
    return [self packageIDIsInstalled:package.identifier version:strict ? package.version : NULL];
}

- (BOOL)packageIDIsAvailable:(NSString *)packageIdentifier version:(NSString *_Nullable)version {
    if ([self openDatabase] == SQLITE_OK) {
        BOOL packageIsAvailable = NO;
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT PACKAGE FROM PACKAGES WHERE PACKAGE = ? AND REPOID > 0 LIMIT 1;", -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
            while (sqlite3_step(statement) == SQLITE_ROW) {
                packageIsAvailable = YES;
                break;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return packageIsAvailable;
    } else {
        [self printDatabaseError];
    }
    return NO;
}

- (BOOL)packageIsAvailable:(ZBPackage *)package versionStrict:(BOOL)strict {
    return [self packageIDIsAvailable:package.identifier version:strict ? package.version : NULL];
}

- (ZBPackage * _Nullable)packageForID:(NSString *)identifier equalVersion:(NSString *)version {
    if ([self openDatabase] == SQLITE_OK) {
        ZBPackage *package = nil;
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT * FROM PACKAGES WHERE PACKAGE = ? AND VERSION = ? LIMIT 1;", -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [identifier UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [version UTF8String], -1, SQLITE_TRANSIENT);
            while (sqlite3_step(statement) == SQLITE_ROW) {
                package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                break;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return package;
    } else {
        [self printDatabaseError];
    }
    return nil;
}

- (BOOL)areUpdatesIgnoredForPackage:(ZBPackage *)package {
    return [self areUpdatesIgnoredForPackageIdentifier:[package identifier]];
}

- (BOOL)areUpdatesIgnoredForPackageIdentifier:(NSString *)identifier {
    if ([self openDatabase] == SQLITE_OK) {
        BOOL ignored = NO;
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT IGNORE FROM UPDATES WHERE PACKAGE = ? LIMIT 1;", -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [identifier UTF8String], -1, SQLITE_TRANSIENT);
            while (sqlite3_step(statement) == SQLITE_ROW) {
                if (sqlite3_column_int(statement, 0) == 1)
                    ignored = YES;
                break;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return ignored;
    } else {
        [self printDatabaseError];
    }
    return NO;
}

- (void)setUpdatesIgnored:(BOOL)ignore forPackage:(ZBPackage *)package {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"REPLACE INTO UPDATES(PACKAGE, VERSION, IGNORE) VALUES(\'%@\', \'%@\', %d);", package.identifier, package.version, ignore ? 1 : 0];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                break;
            }
        } else {
            NSLog(@"[Zebra] Error preparing setting package ignore updates statement: %s", sqlite3_errmsg(database));
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
    } else {
        [self printDatabaseError];
    }
}

#pragma mark - Package lookup

- (ZBPackage * _Nullable)packageThatProvides:(NSString *)identifier thatSatisfiesComparison:(NSString *)comparison ofVersion:(NSString *)version {
    return [self packageThatProvides:identifier thatSatisfiesComparison:comparison ofVersion:version thatIsNot:NULL];
}

- (ZBPackage * _Nullable)packageThatProvides:(NSString *)packageIdentifier thatSatisfiesComparison:(NSString *)comparison ofVersion:(NSString *)version thatIsNot:(ZBPackage * _Nullable)exclude {
    if ([self openDatabase] == SQLITE_OK) {
        packageIdentifier = [packageIdentifier lowercaseString];
        
        const char *query;
        const char *firstSearchTerm = [[NSString stringWithFormat:@"%%, %@ (%%", packageIdentifier] UTF8String];
        const char *secondSearchTerm = [[NSString stringWithFormat:@"%%, %@, %%", packageIdentifier] UTF8String];
        const char *thirdSearchTerm = [[NSString stringWithFormat:@"%@ (%%", packageIdentifier] UTF8String];
        const char *fourthSearchTerm = [[NSString stringWithFormat:@"%@, %%", packageIdentifier] UTF8String];
        const char *fifthSearchTerm = [[NSString stringWithFormat:@"%%, %@", packageIdentifier] UTF8String];
        const char *sixthSearchTerm = [[NSString stringWithFormat:@"%%| %@", packageIdentifier] UTF8String];
        const char *seventhSearchTerm = [[NSString stringWithFormat:@"%%, %@ |%%", packageIdentifier] UTF8String];
        const char *eighthSearchTerm = [[NSString stringWithFormat:@"%@ |%%", packageIdentifier] UTF8String];
        
        if (exclude) {
            query = "SELECT * FROM PACKAGES WHERE PACKAGE != ? AND REPOID > 0 AND (PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ?) AND REPOID > 0 LIMIT 1;";
        }
        else {
            query = "SELECT * FROM PACKAGES WHERE REPOID > 0 AND (PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ?) LIMIT 1;";
        }
        
        NSMutableArray <ZBPackage *> *packages = [NSMutableArray new];
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK) {
            if (exclude) {
                sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
            }
            sqlite3_bind_text(statement, exclude ? 2 : 1, firstSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 3 : 2, secondSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 4 : 3, thirdSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 5 : 4, fourthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 6 : 5, fifthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 7 : 6, sixthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 8 : 7, seventhSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 9 : 8, eighthSearchTerm, -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *providesLine = (const char *)sqlite3_column_text(statement, ZBPackageColumnProvides);
                if (providesLine != 0) {
                    NSString *provides = [[NSString stringWithUTF8String:providesLine] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    NSArray *virtualPackages = [provides componentsSeparatedByString:@","];
                    
                    for (NSString *virtualPackage in virtualPackages) {
                        NSArray *versionComponents = [ZBDependencyResolver separateVersionComparison:[virtualPackage stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                        if ([versionComponents[0] isEqualToString:packageIdentifier] &&
                            ([versionComponents[2] isEqualToString:@"0:0"] || [ZBDependencyResolver doesVersion:versionComponents[2] satisfyComparison:comparison ofVersion:version])) {
                            ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                            [packages addObject:package];
                            break;
                        }
                    }
                }
            }
        } else {
            [self printDatabaseError];
            return NULL;
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        return [packages count] ? packages[0] : NULL; //Returns the first package in the array, we could use interactive dependency resolution in the future
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (ZBPackage * _Nullable)installedPackageThatProvides:(NSString *)identifier thatSatisfiesComparison:(NSString *)comparison ofVersion:(NSString *)version {
    return [self installedPackageThatProvides:identifier thatSatisfiesComparison:comparison ofVersion:version thatIsNot:NULL];
}

- (ZBPackage * _Nullable)installedPackageThatProvides:(NSString *)packageIdentifier thatSatisfiesComparison:(NSString *)comparison ofVersion:(NSString *)version thatIsNot:(ZBPackage *_Nullable)exclude {
    if ([self openDatabase] == SQLITE_OK) {
        const char *query;
        const char *firstSearchTerm = [[NSString stringWithFormat:@"%%, %@ (%%", packageIdentifier] UTF8String];
        const char *secondSearchTerm = [[NSString stringWithFormat:@"%%, %@, %%", packageIdentifier] UTF8String];
        const char *thirdSearchTerm = [[NSString stringWithFormat:@"%@ (%%", packageIdentifier] UTF8String];
        const char *fourthSearchTerm = [[NSString stringWithFormat:@"%@, %%", packageIdentifier] UTF8String];
        const char *fifthSearchTerm = [[NSString stringWithFormat:@"%%, %@", packageIdentifier] UTF8String];
        const char *sixthSearchTerm = [[NSString stringWithFormat:@"%%| %@", packageIdentifier] UTF8String];
        const char *seventhSearchTerm = [[NSString stringWithFormat:@"%%, %@ |%%", packageIdentifier] UTF8String];
        const char *eighthSearchTerm = [[NSString stringWithFormat:@"%@ |%%", packageIdentifier] UTF8String];
        
        if (exclude) {
            query = "SELECT * FROM PACKAGES WHERE PACKAGE != ? AND REPOID = 0 AND (PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ?) AND REPOID > 0 LIMIT 1;";
        }
        else {
            query = "SELECT * FROM PACKAGES WHERE REPOID = 0 AND (PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ?) LIMIT 1;";
        }
        
        NSMutableArray <ZBPackage *> *packages = [NSMutableArray new];
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK) {
            if (exclude) {
                sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
            }
            sqlite3_bind_text(statement, exclude ? 2 : 1, firstSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 3 : 2, secondSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 4 : 3, thirdSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 5 : 4, fourthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 6 : 5, fifthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 7 : 6, sixthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 8 : 7, seventhSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, exclude ? 9 : 8, eighthSearchTerm, -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                [packages addObject:package];
            }
        } else {
            [self printDatabaseError];
            return NULL;
        }
        sqlite3_finalize(statement);
        
        for (ZBPackage *package in packages) {
            //If there is a comparison and a version then we return the first package that satisfies this comparison, otherwise we return the first package we see
            //(this also sets us up better later for interactive dependency resolution)
            if (comparison && version && [ZBDependencyResolver doesPackage:package satisfyComparison:comparison ofVersion:version]) {
                [self closeDatabase];
                return package;
            }
            else if (!comparison || !version) {
                [self closeDatabase];
                return package;
            }
        }
        
        [self closeDatabase];
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (ZBPackage * _Nullable)packageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version {
    return [self packageForIdentifier:identifier thatSatisfiesComparison:comparison ofVersion:version includeVirtualPackages:YES];
}

- (ZBPackage * _Nullable)packageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version includeVirtualPackages:(BOOL)checkVirtual {
    if ([self openDatabase] == SQLITE_OK) {
        ZBPackage *package = nil;
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT * FROM PACKAGES WHERE PACKAGE = ? COLLATE NOCASE AND REPOID > 0 LIMIT 1;", -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [identifier UTF8String], -1, SQLITE_TRANSIENT);
            while (sqlite3_step(statement) == SQLITE_ROW) {
                package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                break;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        // Only try to resolve "Provides" if we can't resolve the normal package.
        if (checkVirtual && package == NULL) {
            package = [self packageThatProvides:identifier thatSatisfiesComparison:comparison ofVersion:version]; //there is a scenario here where two packages that provide a package could be found (ex: anemone, snowboard, and ithemer all provide winterboard) we need to ask the user which one to pick.
        }
        
        if (package != NULL) {
            NSArray *otherVersions = [self allVersionsForPackage:package];
            if (version != NULL && comparison != NULL) {
                if ([otherVersions count] > 1) {
                    for (ZBPackage *package in otherVersions) {
                        if ([ZBDependencyResolver doesPackage:package satisfyComparison:comparison ofVersion:version]) {
                            [self closeDatabase];
                            return package;
                        }
                    }
                    
                    [self closeDatabase];
                    return NULL;
                }
                [self closeDatabase];
                return [ZBDependencyResolver doesPackage:otherVersions[0] satisfyComparison:comparison ofVersion:version] ? otherVersions[0] : NULL;
            }
            return otherVersions[0];
        }
        
        [self closeDatabase];
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (ZBPackage * _Nullable)installedPackageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version {
    return [self installedPackageForIdentifier:identifier thatSatisfiesComparison:comparison ofVersion:version includeVirtualPackages:YES thatIsNot:NULL];
}

- (ZBPackage * _Nullable)installedPackageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version includeVirtualPackages:(BOOL)checkVirtual {
    return [self installedPackageForIdentifier:identifier thatSatisfiesComparison:comparison ofVersion:version includeVirtualPackages:checkVirtual thatIsNot:NULL];
}

- (ZBPackage * _Nullable)installedPackageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version includeVirtualPackages:(BOOL)checkVirtual thatIsNot:(ZBPackage *_Nullable)exclude {
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query;
        if (exclude) {
            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE = '\%@\' COLLATE NOCASE AND REPOID = 0 AND PACKAGE != '\%@\' LIMIT 1;", identifier, [exclude identifier]];
        }
        else {
            query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE = '\%@\' COLLATE NOCASE AND REPOID = 0 LIMIT 1;", identifier];
        }
        
        ZBPackage *package;
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                break;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        
        // Only try to resolve "Provides" if we can't resolve the normal package.
        if (checkVirtual && package == NULL) {
            package = [self installedPackageThatProvides:identifier thatSatisfiesComparison:comparison ofVersion:version thatIsNot:exclude]; //there is a scenario here where two packages that provide a package could be found (ex: anemone, snowboard, and ithemer all provide winterboard) we need to ask the user which one to pick.
        }
        
        if (package != NULL) {
            [self closeDatabase];
            if (version != NULL && comparison != NULL) {
                return [ZBDependencyResolver doesPackage:package satisfyComparison:comparison ofVersion:version] ? package : NULL;
            }
            return package;
        }
        
        [self closeDatabase];
    } else {
        [self printDatabaseError];
    }
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
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *allVersions = [NSMutableArray new];
        
        NSString *query;
        sqlite3_stmt *statement = NULL;
        if (source != NULL) {
            query = @"SELECT * FROM PACKAGES WHERE PACKAGE = ? AND REPOID = ?;";
        }
        else {
            query = @"SELECT * FROM PACKAGES WHERE PACKAGE = ?;";
        }
        
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
            if (source != NULL) {
                sqlite3_bind_int(statement, 2, [source sourceID]);
            }
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
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSArray * _Nullable)otherVersionsForPackage:(ZBPackage *)package {
    return [self otherVersionsForPackageID:package.identifier version:package.version];
}

- (NSArray * _Nullable)otherVersionsForPackageID:(NSString *)packageIdentifier version:(NSString *)version {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *otherVersions = [NSMutableArray new];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT * FROM PACKAGES WHERE PACKAGE = ? AND VERSION != ?;", -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [version UTF8String], -1, SQLITE_TRANSIENT);
        }
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int sourceID = sqlite3_column_int(statement, ZBPackageColumnSourceID);
            if (sourceID > 0) {
                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                
                [otherVersions addObject:package];
            }
        }
        sqlite3_finalize(statement);
        
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        NSArray *sorted = [otherVersions sortedArrayUsingDescriptors:@[sort]];
        [self closeDatabase];
        
        return sorted;
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSArray * _Nullable)packagesByAuthorName:(NSString *)name email:(NSString *_Nullable)email fullSearch:(BOOL)fullSearch {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *searchResults = [NSMutableArray new];
        
        sqlite3_stmt *statement = NULL;
        NSString *columns = fullSearch ? @"*" : @"PACKAGE, NAME, VERSION, REPOID, SECTION, ICONURL";
        NSString *emailMatch = email ? @" AND AUTHOREMAIL = ?" : @"";
        NSString *limit = fullSearch ? @";" : @" LIMIT 30;";
        NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM PACKAGES WHERE AUTHORNAME = ? OR AUTHORNAME LIKE \'%%%@%%\'%@%@", columns, name, emailMatch, limit];
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [name UTF8String], -1, SQLITE_TRANSIENT);
            if (email) sqlite3_bind_text(statement, 2, [email UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                if (fullSearch) {
                    const char *packageIDChars = (const char *)sqlite3_column_text(statement, 0);
                    if (packageIDChars != 0) {
                        NSString *packageID = [NSString stringWithUTF8String:packageIDChars];
                        ZBPackage *package = [self topVersionForPackageID:packageID];
                        if (package) [searchResults addObject:package];
                    }
                }
                else {
                    ZBProxyPackage *proxyPackage = [[ZBProxyPackage alloc] initWithSQLiteStatement:statement];
                    
                    const char *sectionChars = (const char *)sqlite3_column_text(statement, 4);
                    const char *iconURLChars = (const char *)sqlite3_column_text(statement, 5);
                    
                    NSString *section = sectionChars != 0 ? [NSString stringWithUTF8String:sectionChars] : NULL;
                    NSString *iconURLString = iconURLChars != 0 ? [NSString stringWithUTF8String:iconURLChars] : NULL;
                    NSURL *iconURL = [NSURL URLWithString:iconURLString];
                    
                    if (section) proxyPackage.section = section;
                    if (iconURL) proxyPackage.iconURL = iconURL;
                    
                    [searchResults addObject:proxyPackage];
                }
            }
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        
        return [self cleanUpDuplicatePackages:searchResults];
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSArray * _Nullable)packagesWithDescription:(NSString *)description fullSearch:(BOOL)fullSearch {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *searchResults = [NSMutableArray new];
        
        sqlite3_stmt *statement = NULL;
        NSString *columns = fullSearch ? @"*" : @"PACKAGE, NAME, VERSION, REPOID, SECTION, ICONURL";
        NSString *limit = fullSearch ? @";" : @" LIMIT 30;";
        NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM PACKAGES WHERE SHORTDESCRIPTION LIKE \'%%%@%%\'%@", columns, description, limit];
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                if (fullSearch) {
                    const char *packageIDChars = (const char *)sqlite3_column_text(statement, 0);
                    if (packageIDChars != 0) {
                        NSString *packageID = [NSString stringWithUTF8String:packageIDChars];
                        ZBPackage *package = [self topVersionForPackageID:packageID];
                        if (package) [searchResults addObject:package];
                    }
                }
                else {
                    ZBProxyPackage *proxyPackage = [[ZBProxyPackage alloc] initWithSQLiteStatement:statement];
                    
                    const char *sectionChars = (const char *)sqlite3_column_text(statement, 4);
                    const char *iconURLChars = (const char *)sqlite3_column_text(statement, 5);
                    
                    NSString *section = sectionChars != 0 ? [NSString stringWithUTF8String:sectionChars] : NULL;
                    NSString *iconURLString = iconURLChars != 0 ? [NSString stringWithUTF8String:iconURLChars] : NULL;
                    NSURL *iconURL = [NSURL URLWithString:iconURLString];
                    
                    if (section) proxyPackage.section = section;
                    if (iconURL) proxyPackage.iconURL = iconURL;
                    
                    [searchResults addObject:proxyPackage];
                }
            }
        }
        sqlite3_finalize(statement);
        
        [self closeDatabase];
        
        return [self cleanUpDuplicatePackages:searchResults];
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSArray * _Nullable)packagesWithReachableIcon:(int)limit excludeFrom:(NSArray <ZBSource *> *_Nullable)blacklistedSources {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *packages = [NSMutableArray new];
        NSMutableArray *sourceIDs = [@[[NSNumber numberWithInt:-1], [NSNumber numberWithInt:0]] mutableCopy];
        
        for (ZBSource *source in blacklistedSources) {
            [sourceIDs addObject:[NSNumber numberWithInt:[source sourceID]]];
        }
        NSString *excludeString = [NSString stringWithFormat:@"(%@)", [sourceIDs componentsJoinedByString:@", "]];
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE REPOID NOT IN %@ AND ICONURL IS NOT NULL ORDER BY RANDOM() LIMIT %d;", excludeString, limit];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *package = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                [packages addObject:package];
 
            }
        }
        [self closeDatabase];
        return [self cleanUpDuplicatePackages:packages];
    } else {
        [self printDatabaseError];
    }
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
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *packages = [NSMutableArray new];
        
        const char *firstSearchTerm = [[NSString stringWithFormat:@"%%, %@ (%%", packageIdentifier] UTF8String];
        const char *secondSearchTerm = [[NSString stringWithFormat:@"%%, %@, %%", packageIdentifier] UTF8String];
        const char *thirdSearchTerm = [[NSString stringWithFormat:@"%@ (%%", packageIdentifier] UTF8String];
        const char *fourthSearchTerm = [[NSString stringWithFormat:@"%@, %%", packageIdentifier] UTF8String];
        const char *fifthSearchTerm = [[NSString stringWithFormat:@"%%, %@", packageIdentifier] UTF8String];
        const char *sixthSearchTerm = [[NSString stringWithFormat:@"%%| %@", packageIdentifier] UTF8String];
        const char *seventhSearchTerm = [[NSString stringWithFormat:@"%%, %@ |%%", packageIdentifier] UTF8String];
        const char *eighthSearchTerm = [[NSString stringWithFormat:@"%@ |%%", packageIdentifier] UTF8String];
        
        const char *query = "SELECT * FROM PACKAGES WHERE (DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS LIKE ? OR DEPENDS = ?) AND REPOID = 0;";
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, firstSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, secondSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, thirdSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, fourthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, fifthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, sixthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 7, seventhSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 8, eighthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 9, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *dependsChars = (const char *)sqlite3_column_text(statement, ZBPackageColumnDepends);
                NSString *depends = dependsChars != 0 ? [NSString stringWithUTF8String:dependsChars] : NULL; //Depends shouldn't be NULL here but you know just in case because this can be weird
                NSArray *dependsOn = [depends componentsSeparatedByString:@", "];
                
                BOOL packageNeedsToBeRemoved = NO;
                for (NSString *dependsLine in dependsOn) {
                    NSError *error = NULL;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\b%@\\b", [package identifier]] options:NSRegularExpressionCaseInsensitive error:&error];
                    if ([regex numberOfMatchesInString:dependsLine options:0 range:NSMakeRange(0, [dependsLine length])] && ![self willDependencyBeSatisfiedAfterQueueOperations:dependsLine]) { //Use regex to search with block words
                        packageNeedsToBeRemoved = YES;
                    }
                }

                if (packageNeedsToBeRemoved) {
                    ZBPackage *found = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                    if ([[ZBQueue sharedQueue] locate:found] == ZBQueueTypeClear) {
                        [found setRemovedBy:package];

                        [packages addObject:found];
                    }
                }
            }
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
        
        for (NSString *provided in [package provides]) { //If the package is removed and there is no other package that provides this dependency, we have to remove those as well
            if ([provided containsString:packageIdentifier]) continue;
            if (![[package identifier] isEqualToString:packageIdentifier] && [[package provides] containsObject:provided]) continue;
            if (![self willDependencyBeSatisfiedAfterQueueOperations:provided]) {
                [packages addObjectsFromArray:[self packagesThatDependOnPackageIdentifier:provided removedPackage:package]];
            }
        }
        
        return [packages count] > 0 ? packages : NULL;
    } else {
        [self printDatabaseError];
    }
    return NULL;
}

- (NSArray <ZBPackage *> * _Nullable)packagesThatConflictWith:(ZBPackage *)package {
    if ([self openDatabase] == SQLITE_OK) {
        NSMutableArray *packages = [NSMutableArray new];
        
        const char *firstSearchTerm = [[NSString stringWithFormat:@"%%, %@ (%%", [package identifier]] UTF8String];
        const char *secondSearchTerm = [[NSString stringWithFormat:@"%%, %@, %%", [package identifier]] UTF8String];
        const char *thirdSearchTerm = [[NSString stringWithFormat:@"%@ (%%", [package identifier]] UTF8String];
        const char *fourthSearchTerm = [[NSString stringWithFormat:@"%@, %%", [package identifier]] UTF8String];
        const char *fifthSearchTerm = [[NSString stringWithFormat:@"%%, %@", [package identifier]] UTF8String];
        const char *sixthSearchTerm = [[NSString stringWithFormat:@"%%| %@", [package identifier]] UTF8String];
        const char *seventhSearchTerm = [[NSString stringWithFormat:@"%%, %@ |%%", [package identifier]] UTF8String];
        const char *eighthSearchTerm = [[NSString stringWithFormat:@"%@ |%%", [package identifier]] UTF8String];
        
        const char *query = "SELECT * FROM PACKAGES WHERE (CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS LIKE ? OR CONFLICTS = ?) AND REPOID = 0;";
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, firstSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, secondSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, thirdSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, fourthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, fifthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, sixthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 7, seventhSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 8, eighthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 9, [[package identifier] UTF8String], -1, SQLITE_TRANSIENT);
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBPackage *found = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                [packages addObject:found];
            }
        }
        
        for (ZBPackage *conflictingPackage in [packages copy]) {
            for (NSString *conflict in [conflictingPackage conflictsWith]) {
                if (([conflict containsString:@"("] || [conflict containsString:@")"]) && [conflict containsString:[package identifier]]) {
                    NSArray *versionComparison = [ZBDependencyResolver separateVersionComparison:conflict];
                    if (![ZBDependencyResolver doesPackage:package satisfyComparison:versionComparison[1] ofVersion:versionComparison[2]]) {
                        [packages removeObject:conflictingPackage];
                    }
                }
            }
        }
        
        [self closeDatabase];
        return [packages count] > 0 ? packages : NULL;
    } else {
        [self printDatabaseError];
    }
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
    if ([dependency containsString:@"|"]) {
        NSArray *components = [dependency componentsSeparatedByString:@"|"];
        for (NSString *dependency in components) {
            if ([self willDependencyBeSatisfiedAfterQueueOperations:[dependency stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]]) {
                return YES;
            }
        }
    }
    else if ([self openDatabase] == SQLITE_OK) {
        ZBQueue *queue = [ZBQueue sharedQueue];
        NSArray *addedPackages =   [queue packagesQueuedForAdddition]; //Packages that are being installed, upgraded, removed, downgraded, etc. (dependencies as well)
        NSArray *removedPackages = [queue packageIDsQueuedForRemoval]; //Just packageIDs that are queued for removal (conflicts as well)
        
        NSArray *versionComponents = [ZBDependencyResolver separateVersionComparison:dependency];
        NSString *packageIdentifier = versionComponents[0];
        BOOL needsVersionComparison = ![versionComponents[1] isEqualToString:@"<=>"] && ![versionComponents[2] isEqualToString:@"0:0"];
        
        NSString *excludeString = [self excludeStringFromArray:removedPackages];
        const char *firstSearchTerm = [[NSString stringWithFormat:@"%%, %@ (%%", packageIdentifier] UTF8String];
        const char *secondSearchTerm = [[NSString stringWithFormat:@"%%, %@, %%", packageIdentifier] UTF8String];
        const char *thirdSearchTerm = [[NSString stringWithFormat:@"%@ (%%", packageIdentifier] UTF8String];
        const char *fourthSearchTerm = [[NSString stringWithFormat:@"%@, %%", packageIdentifier] UTF8String];
        const char *fifthSearchTerm = [[NSString stringWithFormat:@"%%, %@", packageIdentifier] UTF8String];
        const char *sixthSearchTerm = [[NSString stringWithFormat:@"%%| %@", packageIdentifier] UTF8String];
        const char *seventhSearchTerm = [[NSString stringWithFormat:@"%%, %@ |%%", packageIdentifier] UTF8String];
        const char *eighthSearchTerm = [[NSString stringWithFormat:@"%@ |%%", packageIdentifier] UTF8String];
        
        NSString *query = [NSString stringWithFormat:@"SELECT VERSION FROM PACKAGES WHERE PACKAGE NOT IN %@ AND REPOID = 0 AND (PACKAGE = ? OR (PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ? OR PROVIDES LIKE ?)) LIMIT 1;", excludeString];
        
        BOOL found = NO;
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [packageIdentifier UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, firstSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, secondSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, thirdSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, fourthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, fifthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 7, sixthSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 8, seventhSearchTerm, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 9, eighthSearchTerm, -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                if (needsVersionComparison) {
                    const char* foundVersion = (const char*)sqlite3_column_text(statement, 0);
                    
                    if (foundVersion != 0) {
                        if ([ZBDependencyResolver doesVersion:[NSString stringWithUTF8String:foundVersion] satisfyComparison:versionComponents[1] ofVersion:versionComponents[2]]) {
                            found = YES;
                            break;
                        }
                    }
                }
                else {
                    found = YES;
                    break;
                }
            }
            
            if (!found) { //Search the array of packages that are queued for installation to see if one of them satisfies the dependency
                for (NSDictionary *package in addedPackages) {
                    if ([[package objectForKey:@"identifier"] isEqualToString:packageIdentifier]) {
                        // TODO: Condition check here is useless
//                        if (needsVersionComparison && [ZBDependencyResolver doesVersion:[package objectForKey:@"version"] satisfyComparison:versionComponents[1] ofVersion:versionComponents[2]]) {
//                            return YES;
//                        }
                        return YES;
                    }
                }
                return NO;
            }
            
            sqlite3_finalize(statement);
            [self closeDatabase];
            return found;
        } else {
            [self printDatabaseError];
        }
        [self closeDatabase];
    }
    else {
        [self printDatabaseError];
    }
    return NO;
}

#pragma mark - Download Delegate

- (void)startedDownloads {
    if (!completedSources) {
        completedSources = [NSMutableArray new];
    }
}

- (void)startedSourceDownload:(ZBBaseSource *)baseSource {
    [self postStatusUpdate:[NSString stringWithFormat:NSLocalizedString(@"Downloading %@", @""), [baseSource repositoryURI]] atLevel:ZBLogLevelDescript];
}

- (void)progressUpdate:(CGFloat)progress forSource:(ZBBaseSource *)baseSource {
    //TODO: Implement
}

- (void)finishedSourceDownload:(ZBBaseSource *)baseSource withErrors:(NSArray <NSError *> *_Nullable)errors {
    [self postStatusUpdate:[NSString stringWithFormat:NSLocalizedString(@"Done %@", @""), [baseSource repositoryURI]] atLevel:ZBLogLevelDescript];
    if (baseSource) [completedSources addObject:baseSource];
}

- (void)finishedAllDownloads {
    [self parseSources:[completedSources copy]];
    [completedSources removeAllObjects];
}

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    [self bulkPostStatusUpdate:status atLevel:level];
}


#pragma mark - Helper methods

- (NSArray *)cleanUpDuplicatePackages:(NSArray <ZBPackage *> *)packageList {
    NSMutableDictionary *packageVersionDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *results = [NSMutableArray array];
    
    for (ZBPackage *package in packageList) {
        ZBPackage *packageFromDict = packageVersionDict[package.identifier];
        if (packageFromDict == NULL) {
            packageVersionDict[package.identifier] = package;
            [results addObject:package];
            continue;
        }
        
        if ([package sameAs:packageFromDict]) {
            NSString *packageDictVersion = [packageFromDict version];
            NSString *packageVersion = package.version;
            int result = compare([packageVersion UTF8String], [packageDictVersion UTF8String]);
            
            if (result > 0) {
                NSUInteger index = [results indexOfObject:packageFromDict];
                packageVersionDict[package.identifier] = package;
                [results replaceObjectAtIndex:index withObject:package];
            }
        }
    }
    
    return results;
}

- (void)checkForZebraSource {
    NSError *readError = NULL;
    NSString *sources = [NSString stringWithContentsOfFile:[ZBAppDelegate sourcesListPath] encoding:NSUTF8StringEncoding error:&readError];
    if (readError != nil) {
        NSLog(@"[Zebra] Error while reading source list");
    }

    if (![sources containsString:@"deb https://getzbra.com/repo/ ./"]) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:[ZBAppDelegate sourcesListPath]];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[@"\ndeb https://getzbra.com/repo/ ./\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    }
}

- (ZBPackage *)localVersionForPackage:(ZBPackage *)package {
    if ([[package source] sourceID] == 0) return package;
    if (![package isInstalled:NO]) return NULL;
    
    ZBPackage *localPackage = NULL;
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM PACKAGES WHERE PACKAGE = '%@' AND REPOID = 0", [package identifier]];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                localPackage = [[ZBPackage alloc] initWithSQLiteStatement:statement];
                break;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
    } else {
        [self printDatabaseError];
    }
    
    return localPackage;
}

- (NSString * _Nullable)installedVersionForPackage:(ZBPackage *)package {
    NSString *version = NULL;
    if ([self openDatabase] == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT VERSION FROM PACKAGES WHERE PACKAGE = '%@' AND REPOID = 0", [package identifier]];
        
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *versionChars = (const char *)sqlite3_column_text(statement, 0);
                if (versionChars != 0) {
                    version = [NSString stringWithUTF8String:versionChars];
                }
                break;
            }
        } else {
            [self printDatabaseError];
        }
        sqlite3_finalize(statement);
        [self closeDatabase];
    } else {
        [self printDatabaseError];
    }
    
    return version;
}

- (NSString * _Nullable)excludeStringFromArray:(NSArray *)array {
    if ([array count]) {
        NSMutableString *result = [@"(" mutableCopy];
        [result appendString:[NSString stringWithFormat:@"\'%@\'", array[0]]];
        for (int i = 1; i < array.count; ++i) {
            [result appendFormat:@", \'%@\'", array[i]];
        }
        [result appendString:@")"];
        
        return result;
    }
    return NULL;
}

@end
