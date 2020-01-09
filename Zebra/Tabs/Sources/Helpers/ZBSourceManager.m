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

@interface ZBSourceManager () {
    NSMutableDictionary <NSNumber *, ZBSource *> *repos;
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

- (NSMutableDictionary <NSNumber *, ZBSource *> *)repos {
    if (recachingNeeded) {
        recachingNeeded = NO;
        repos = [NSMutableDictionary new];
        NSString *query = @"SELECT * FROM REPOS;";

        sqlite3 *database;
        sqlite3_open([[ZBAppDelegate databaseLocation] UTF8String], &database);

        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBSource *source = [[ZBSource alloc] initWithSQLiteStatement:statement];
                repos[@(source.repoID)] = source;
            }
        } else {
            [[ZBDatabaseManager sharedInstance] printDatabaseError];
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }
    return repos;
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
            @"deb http://cydia.zodttd.com/repo/cydia/ stable main",
            @"deb http://cydia.zodttd.com/repo/cydia/ stable main"
        ];
    });
    return lines;
}

+ (NSString *_Nullable)debLineForURL:(NSURL *)URL {
    NSUInteger index = [[self knownDistURLs] indexOfObject:[URL host]];
    if (index != NSNotFound) {
        return [[self knownDebLines] objectAtIndex:index];
    }
    else {
        return [NSString stringWithFormat:@"deb %@ ./", [URL absoluteString]];
    }
}

- (void)addBaseSources:(NSSet <ZBBaseSource *> *)baseSources {
    [self appendBaseSources:baseSources toFile:[ZBAppDelegate sourcesListPath]];
}

- (void)deleteSource:(ZBSource *)source {
    [self deleteBaseSource:source];
    
    if ([source isKindOfClass:[ZBSource class]]) {
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        [databaseManager deleteRepo:source];
    }
}

- (void)deleteBaseSource:(ZBBaseSource *)source {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    
    NSMutableSet *sourcesToWrite = [[databaseManager sources] mutableCopy];
    [sourcesToWrite removeObject:source];
    
    [self writeBaseSources:sourcesToWrite toFile:[ZBAppDelegate sourcesListPath]];
}

//TODO: This needs error pointers
- (void)appendBaseSources:(NSSet <ZBBaseSource *> *)sources toFile:(NSString *)filePath {
    NSError *error;
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
    
    NSError *error;
    [[debLines componentsJoinedByString:@""] writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        NSLog(@"[Zebra] Error while writing sources to file: %@", error);
    }
    
    recachingNeeded = TRUE;
}

//TODO: This needs error pointers
- (void)addDebLine:(NSString *)sourceLine {
    NSString *listsLocation = [ZBAppDelegate sourcesListPath];
    NSError *readError;
    NSString *output = [NSString stringWithContentsOfFile:listsLocation encoding:NSUTF8StringEncoding error:&readError];
    if (readError != NULL) {
        NSLog(@"[Zebra] Error while writing sources to file: %@", readError);
    }
    
    output = [output stringByAppendingString:sourceLine];
    
    NSError *error;
    [output writeToFile:listsLocation atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        NSLog(@"[Zebra] Error while writing sources to file: %@", error);
    }
}

- (void)verifySources:(NSSet <ZBBaseSource *> *)sources delegate:(id <ZBSourceVerificationDelegate>)delegate {
    for (ZBBaseSource *source in sources) {
        [self verifySource:source delegate:delegate];
    }
}

- (void)verifySource:(ZBBaseSource *)source delegate:(id <ZBSourceVerificationDelegate>)delegate {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [source verify:^(ZBSourceVerification status) {
            [delegate source:source status:status];
        }];
    });
}

@end
