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

- (NSURL *)normalizedURL:(NSURL *)url {
    NSString *absoluteString = [url absoluteString];
    char lastChar = [absoluteString characterAtIndex:absoluteString.length - 1];
    return lastChar == '/' ? url : [url URLByAppendingPathComponent:@"/"];
}

- (NSString *)normalizedURLString:(NSURL *)url {
    NSURL *normalizedURL = [self normalizedURL:url];
    NSString *urlString = [normalizedURL absoluteString];
    return [[urlString stringByReplacingOccurrencesOfString:[normalizedURL scheme] withString:@""] substringFromIndex:3]; // Remove http:// or https:// from url
}

+ (NSArray <NSString *> *)knownDistURLs {
    static NSArray *urls = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        urls = @[@"apt.thebigboss.org/",
            @"apt.thebigboss.org/repofiles/cydia/",
            @"apt.modmyi.com/",
            @"apt.saurik.com/",
            @"apt.bingner.com/",
            @"cydia.zodttd.com/",
            @"cydia.zodttd.com/repo/cydia/"];
    });
    return urls;
}

+ (NSArray <NSString *> *)knownDebLines {
    static NSArray *lines = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lines = @[
            @"deb http://apt.thebigboss.org/repofiles/cydia/ stable main",
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

- (ZBBaseSource *_Nullable)baseSourceFromDistURL:(NSString *)urlString {
    int index = 0;
    for (NSString *knownURL in [ZBSourceManager knownDistURLs]) {
        if ([urlString containsString:knownURL]) {
            NSString *debLine = [ZBSourceManager knownDebLines][index];
            return [[ZBBaseSource alloc] initFromSourceLine:debLine];
        }
        ++index;
    }
    return NULL;
}

- (void)addSourcesFromString:(NSString *)sourcesString delegate:(id <ZBSourceVerificationDelegate>)delegate {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *detectorError;
        NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&detectorError];
        
        if (detectorError) {
//            completion(@[detectorError], [sourcesString componentsSeparatedByString:@"\n"]); //Return the original string since there was some detector error
            return;
        }
        else {
            NSMutableArray *detectedURLs = [NSMutableArray new];
            
            [detector enumerateMatchesInString:sourcesString options:0 range:NSMakeRange(0, sourcesString.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                if (result.resultType == NSTextCheckingTypeLink) {
                    NSURL *url = [self normalizedURL:result.URL];
                    [detectedURLs addObject:url];
                }
            }];
            
            if (![detectedURLs count]) {
                NSError *URLDetectedError = [NSError errorWithDomain:NSURLErrorDomain code:-72 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"No URLs were detected", @"")}];
//                completion(@[URLDetectedError], NULL);
                return;
            }
            
            NSError *readError;
            NSSet <ZBBaseSource *> *baseSources = [ZBBaseSource baseSourcesFromList:[ZBAppDelegate sourcesListURL] error:&readError];
            NSMutableSet *sources = [NSMutableSet new];
            for (NSURL *detectedURL in detectedURLs) {
                NSString *urlString = [detectedURL absoluteString];
                ZBBaseSource *distSource = [self baseSourceFromDistURL:urlString];
                if (distSource && ![baseSources containsObject:distSource]) {
                    [sources addObject:distSource];
                }
                else {
                    ZBBaseSource *source = [[ZBBaseSource alloc] initWithArchiveType:@"deb" repositoryURI:[detectedURL absoluteString] distribution:@"./" components:NULL];
                    if (source && ![baseSources containsObject:source]) {
                        [sources addObject:source];
                    }
                }
            }
            
            [self verifySources:sources delegate:delegate];
        }
    });
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [source verify:^(ZBSourceVerification status) {
                [delegate source:source status:status];
            }];
        });
    }
}

@end
