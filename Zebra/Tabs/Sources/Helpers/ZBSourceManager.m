//
//  ZBSourceManager.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBSourceManager.h"
#import <UIKit/UIDevice.h>
#import <Sources/Helpers/ZBSource.h>
#import <Database/ZBDatabaseManager.h>
#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <ZBLog.h>

@interface ZBSourceManager () {
    NSMutableDictionary <NSNumber *, ZBSource *> *sources;
    BOOL recachingNeeded;
}
@end

@implementation ZBSourceManager

@synthesize verifiedSources;

+ (id)sharedInstance {
    static ZBSourceManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBSourceManager new];
        instance->recachingNeeded = YES;
    });
    return instance;
}

- (void)needRecaching {
    recachingNeeded = YES;
}

- (NSMutableDictionary <NSNumber *, ZBSource *> *)sources {
    if (recachingNeeded) {
        recachingNeeded = NO;
        sources = [NSMutableDictionary new];

        sqlite3 *database;
        sqlite3_open([[ZBAppDelegate databaseLocation] UTF8String], &database);

        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, "SELECT * FROM REPOS;", -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBSource *source = [[ZBSource alloc] initWithSQLiteStatement:statement];
                sources[@(source.sourceID)] = source;
            }
        } else {
            [[ZBDatabaseManager sharedInstance] printDatabaseError];
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }
    return sources;
}

+ (NSArray <NSString *> *)knownDistURLs {
    static NSArray *urls = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        urls = @[
            @"apt.thebigboss.org",
            @"apt.modmyi.com",
            @"apt.saurik.com",
            @"apt.bingner.com",
            @"cydia.zodttd.com"
        ];
    });
    return urls;
}

+ (NSArray <NSString *> *)knownDebLines {
    static NSArray *lines = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lines = @[
            @"deb http://apt.thebigboss.org/repofiles/cydia/ stable main",
            @"deb http://apt.modmyi.com/ stable main",
            [NSString stringWithFormat:@"deb http://apt.saurik.com/ ios/%.2f main", kCFCoreFoundationVersionNumber],
            [NSString stringWithFormat:@"deb https://apt.bingner.com/ ios/%.2f main", kCFCoreFoundationVersionNumber],
            @"deb http://cydia.zodttd.com/repo/cydia/ stable main"
        ];
    });
    return lines;
}

+ (NSString *_Nullable)debLineForURL:(NSURL *)URL {
    if (!URL) return NULL;
    
    NSUInteger index = [[self knownDistURLs] indexOfObject:[URL host]];
    if (index != NSNotFound) {
        return [[self knownDebLines] objectAtIndex:index];
    }
    else {
        return [NSString stringWithFormat:@"deb %@ ./", [URL absoluteString]];
    }
}

//TODO: This needs error pointers
- (void)addBaseSources:(NSSet <ZBBaseSource *> *)baseSources {
    NSError *readError = NULL;
    NSSet <ZBBaseSource *> *currentSources = [ZBBaseSource baseSourcesFromList:[ZBAppDelegate sourcesListURL] error:&readError];
    
    NSMutableSet *sourcesToAdd = [baseSources mutableCopy];
    for (ZBBaseSource *source in baseSources) {
        if ([currentSources containsObject:source]) {
            ZBLog(@"[Zebra] %@ is already contained in list", source.repositoryURI);
            [sourcesToAdd removeObject:source];
        }
    }
    
    if ([sourcesToAdd count]) [self appendBaseSources:sourcesToAdd toFile:[ZBAppDelegate sourcesListPath]];
}

- (void)deleteSource:(ZBSource *)source {
    if ([source canDelete]) {
        [self deleteBaseSource:source];
        
        if ([source isKindOfClass:[ZBSource class]]) {
            ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
            [databaseManager deleteSource:source];
        }
    }
}

- (void)deleteBaseSource:(ZBBaseSource *)source {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    
    NSMutableSet *sourcesToWrite = [[databaseManager sources] mutableCopy];
    [sourcesToWrite removeObject:source];
    
    [self writeBaseSources:sourcesToWrite toFile:[ZBAppDelegate sourcesListPath]];
    
    //Delete .list file (if it exists)
    NSArray *lists = [self sourceLists:source];
    for (NSString *list in lists) {
        NSString *path = [[ZBAppDelegate listsLocation] stringByAppendingPathComponent:list];
        NSError *error = NULL;
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (!success) {
                NSLog(@"Error removing file at path: %@", error.localizedDescription);
            }
        }
    }
    
    //Delete files from featured.plist (if they exist)
    NSMutableDictionary *featured = [NSMutableDictionary dictionaryWithContentsOfFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"]];
    if ([featured objectForKey:[source baseFilename]]) {
        [featured removeObjectForKey:[source baseFilename]];
    }
    [featured writeToFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"] atomically:NO];
}

//TODO: This needs error pointers
- (void)appendBaseSources:(NSSet <ZBBaseSource *> *)sources toFile:(NSString *)filePath {
    NSError *error = NULL;
    NSString *contents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"[Zebra] ERROR while loading from sources.list: %@", error);
        return;
    }
    else {
        NSMutableArray *debLines = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"\n# Added at %@\n", [NSDate date]]];
        for (ZBBaseSource *baseSource in sources) {
            [debLines addObject:[baseSource debLine]];
        }
        contents = [contents stringByAppendingString:[debLines componentsJoinedByString:@""]];
        [contents writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            NSLog(@"[Zebra] Error while writing sources to file: %@", error);
        }
    }
}

- (void)writeBaseSources:(NSSet <ZBBaseSource *> *)sources toFile:(NSString *)filePath {
    NSMutableArray *debLines = [NSMutableArray new];
    for (ZBBaseSource *baseSource in sources) {
        [debLines addObject:[baseSource debLine]];
    }
    
    NSError *error = NULL;
    [[debLines componentsJoinedByString:@""] writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        NSLog(@"[Zebra] Error while writing sources to file: %@", error);
    }
    
    recachingNeeded = YES;
}

- (void)verifySources:(NSSet <ZBBaseSource *> *)sources delegate:(id <ZBSourceVerificationDelegate>)delegate {
    if ([delegate respondsToSelector:@selector(startedSourceVerification:)]) [delegate startedSourceVerification:[sources count] > 1];
    
    NSUInteger sourcesToVerify = [sources count];
    NSMutableArray *existingSources = [NSMutableArray new];
    NSMutableArray *imaginarySources = [NSMutableArray new];
    
    for (ZBBaseSource *source in sources) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [source verify:^(ZBSourceVerificationStatus status) {
                if ([delegate respondsToSelector:@selector(source:status:)]) [delegate source:source status:status];
                
                if (status == ZBSourceExists) {
                    [existingSources addObject:source];
                }
                else if (status == ZBSourceImaginary) {
                    [imaginarySources addObject:source];
                }
                
                if ([delegate respondsToSelector:@selector(finishedSourceVerification:imaginarySources:)] && sourcesToVerify == [existingSources count] + [imaginarySources count]) {
                    [delegate finishedSourceVerification:existingSources imaginarySources:imaginarySources];
                }
            }];
        });
    }
}

- (NSArray <NSString *> *)sourceLists:(ZBBaseSource *)source {
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[ZBAppDelegate listsLocation] error:nil];
    
    return [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[cd] %@", [source baseFilename]]];
}

@end
