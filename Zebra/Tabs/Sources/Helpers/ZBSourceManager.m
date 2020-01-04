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
            [NSString stringWithFormat:@"deb http://apt.bingner.com/ ios/%.2f main", kCFCoreFoundationVersionNumber],
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

- (void)addSourcesFromString:(NSString *)sourcesString response:(void (^)(BOOL success, BOOL multiple, NSString *error, NSArray<NSURL *> *failedURLs))respond {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            NSError *detectorError = nil;
            NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&detectorError];
            
            if (detectorError) {
                respond(NO, NO, detectorError.localizedDescription, [NSArray array]);
            } else {
                dispatch_group_t group = dispatch_group_create();
                
                dispatch_queue_t sourcesQueue = dispatch_queue_create("xyz.willy.Zebra.addsources", NULL);
                
                NSMutableArray<NSString *> *errors = [NSMutableArray array];
                NSMutableArray<NSURL *> *errorURLs = [NSMutableArray array];
                self->verifiedSources = [NSMutableSet new];
                
                NSMutableSet<NSURL *> *detectedURLs = [NSMutableSet set];
                
                [detector enumerateMatchesInString:sourcesString options:0 range:NSMakeRange(0, sourcesString.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    if (result.resultType == NSTextCheckingTypeLink) {
                        NSURL *url = [self normalizedURL:result.URL];
                        NSLog(@"[Zebra] Detected url: %@", url);
                        
                        [detectedURLs addObject:url];
                    }
                }];
                
                if (detectedURLs.count == 0) {
                    respond(NO, NO, NSLocalizedString(@"No repository urls detected.", @""), @[]);
                    return;
                }
                
                NSError *readError;
                NSString *sourcesList = [NSString stringWithContentsOfURL:[ZBAppDelegate sourcesListURL] encoding:NSUTF8StringEncoding error:&readError];
                NSArray *sourcesListContents = [sourcesList componentsSeparatedByString:@"\n"];
                
                if (readError != NULL) {
                    // rip
                    respond(NO, NO, [NSString stringWithFormat:@"%@ (%@)", readError.localizedDescription, sourcesList], @[]);
                    return;
                }
                
                NSMutableArray *baseURLs = [NSMutableArray new];
                for (NSString *line in sourcesListContents) {
                    NSArray *contents = [line componentsSeparatedByString:@" "];
                    if ([contents count] == 0) continue;
                    
                    if ([contents[0] isEqualToString:@"deb"]) {
                        NSURL *url = [NSURL URLWithString:contents[1]];
                        NSString *urlString = [self normalizedURLString:url];
                        [baseURLs addObject:urlString];
                    }
                }
                
                for (NSURL *detectedURL in detectedURLs) {
                    dispatch_group_enter(group);
                    
                    NSString *urlString = [self normalizedURLString:detectedURL];
                    if ([baseURLs containsObject:urlString]) {
                        NSLog(@"[Zebra] %@ has already been added.", urlString);
                        dispatch_group_leave(group);
                    } else {
                        ZBBaseSource *baseSource = [self baseSourceFromDistURL:urlString];
                        if (baseSource) {
                            [self->verifiedSources addObject:baseSource];
                            
                            dispatch_group_leave(group);
                        } else {
                            ZBBaseSource *source = [[ZBBaseSource alloc] initWithArchiveType:@"deb" repositoryURI:[detectedURL absoluteString] distribution:@"./" components:NULL];
                            [source verify:^(BOOL exists) {
                                dispatch_sync(sourcesQueue, ^{
                                    if (!exists) {
                                        [errors addObject:[NSString stringWithFormat:@"Could not find an APT repository located at %@", detectedURL]];
                                        [errorURLs addObject:detectedURL];
                                        
                                        dispatch_group_leave(group);
                                    } else {
                                        [self->verifiedSources addObject:source];
                                        dispatch_group_leave(group);
                                    }
                                });
                            }];
                        }
                    }
                }
                
                dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                    typeof(self) strongSelf = weakSelf;
                    
                    if (strongSelf) {
                        if ([self->verifiedSources count] == 0 && [errorURLs count] == 0) {
                            respond(NO, NO, NSLocalizedString(@"You have already added these repositories.", @""), @[]);
                        }
                        else {
                            __block NSError *addError = nil;
                            
                            [strongSelf addBaseSources:self->verifiedSources completion:^(BOOL success, NSError *error) {
                                addError = error;
                            }];

                            if (errors.count) {
                                NSString *errorMessage = NSLocalizedString(errors.count == 1 ? @"Error verifying repository" : @"Error verifying repositories", @"");
                                errorMessage = [NSString stringWithFormat:@"%@:\n%@", errorMessage, [errors componentsJoinedByString:@"\n"]];

                                if (addError) {
                                    errorMessage = [NSString stringWithFormat:@"%@\n%@", addError.localizedDescription, errorMessage];
                                }
                                respond(NO, detectedURLs.count > 1, errorMessage, errorURLs);
                            } else {
                                respond(YES, detectedURLs.count > 1, nil, nil);
                            }
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            respond(NO, detectedURLs.count > 1, NSLocalizedString(@"Unknown error", @""), @[]);
                        });
                    }
                });
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                respond(NO, NO, NSLocalizedString(@"Unknown error", @""), @[]);
            });
        }
    });
}

- (void)addBaseSources:(NSSet <ZBBaseSource *> *)baseSources completion:(void (^)(BOOL success, NSError *error))completion {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    
    [self writeBaseSources:[baseSources setByAddingObjectsFromSet:[databaseManager sources]] toFile:[ZBAppDelegate sourcesListPath]];
}

- (void)deleteSource:(ZBSource *)delRepo {
    [self deleteBaseSource:(ZBBaseSource *)delRepo];
    
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    [databaseManager deleteRepo:delRepo];
}

- (void)deleteBaseSource:(ZBBaseSource *)baseSource {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    
    NSMutableSet *sourcesToWrite = [[databaseManager sources] mutableCopy];
    [sourcesToWrite removeObject:baseSource];
    
    [self writeBaseSources:sourcesToWrite toFile:[ZBAppDelegate sourcesListPath]];
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

- (void)transferFromCydia {
    NSURL *listsURL = [ZBAppDelegate sourcesListURL];
    NSURL *cydiaListsURL = [NSURL URLWithString:@"file:///var/mobile/Library/Caches/com.saurik.Cydia/sources.list"];
    
    [self mergeSourcesFrom:cydiaListsURL into:listsURL completion:^(NSError * _Nonnull error) {
        if (error) {
            NSLog(@"[Zebra] Error merging sources: %@", error);
        }
    }];
}

- (void)transferFromSileo {
    NSURL *listsURL = [ZBAppDelegate sourcesListURL];
    NSURL *sileoListsURL = [NSURL URLWithString:@"file:///etc/apt/sources.list.d/sileo.sources"];
    
    [self mergeSourcesFrom:sileoListsURL into:listsURL completion:^(NSError * _Nonnull error) {
        if (error) {
            NSLog(@"[Zebra] Error merging sources: %@", error);
        }
    }];
}

- (void)transferFromInstaller {
    NSURL *listsURL = [ZBAppDelegate sourcesListURL];
    NSURL *installerSourcesURL = [NSURL URLWithString:@"file:///var/mobile/Library/Application%20Support/Installer/APT/sources.list"];
    
    [self mergeSourcesFrom:installerSourcesURL into:listsURL completion:^(NSError * _Nonnull error) {
        if (error) {
            NSLog(@"[Zebra] Error merging sources: %@", error);
        }
    }];
}

- (void)mergeSourcesFrom:(NSURL *)fromURL into:(NSURL *)destinationURL completion:(void (^)(NSError *error))completion {
    if ([[fromURL pathExtension] isEqualToString:@"list"] && [[destinationURL pathExtension] isEqualToString:@"list"]) { // Check to be sure both urls of are type .list
        NSError *readError;
        NSString *destinationString = [NSString stringWithContentsOfURL:destinationURL encoding:NSUTF8StringEncoding error:&readError];
        NSArray *destinationContents = [destinationString componentsSeparatedByString:@"\n"];
        NSArray *sourcesContents = [[NSString stringWithContentsOfURL:fromURL encoding:NSUTF8StringEncoding error:&readError] componentsSeparatedByString:@"\n"];
        if (readError != NULL) {
            NSLog(@"[Zebra] Error while reading: %@", readError.localizedDescription);
            completion(readError);
        }
        
        NSMutableArray *linesToAdd = [NSMutableArray new];
        NSMutableArray *baseURLs = [NSMutableArray new];
        for (NSString *line in destinationContents) {
            NSArray *contents = [line componentsSeparatedByString:@" "];
            if ([contents count] != 0 && [contents[0] isEqualToString:@"deb"]) {
                NSURL *url = [NSURL URLWithString:contents[1]];
                NSString *urlString = [self normalizedURLString:url];
                    
                [baseURLs addObject:urlString];
            }
        }
        
        for (NSString *line in sourcesContents) {
            NSArray *contents = [line componentsSeparatedByString:@" "];
            if ([contents count] != 0 && [contents[0] isEqualToString:@"deb"]) {
                NSURL *url = [NSURL URLWithString:contents[1]];
                NSString *urlString = [self normalizedURLString:url];
                
                if (![baseURLs containsObject:urlString]) {
                    [linesToAdd addObject:[line stringByAppendingString:@"\n"]];
                }
            }
        }
        
        if ([linesToAdd count] != 0) {
            NSMutableString *finalContents = [destinationString mutableCopy];
            [finalContents appendString:[NSString stringWithFormat:@"\n# Imported at %@\n", [NSDate date]]];
            for (NSString *line in linesToAdd) {
                NSLog(@"[Zebra] Adding %@ to sources.list", line);
                [finalContents appendString:line];
            }
            
            NSError *writeError;
            [finalContents writeToURL:destinationURL atomically:NO encoding:NSUTF8StringEncoding error:&writeError];
            if (writeError != NULL) {
                NSLog(@"[Zebra] Error while writing to %@: %@", destinationURL, writeError.localizedDescription);
            }
        }
        
        completion(NULL);
    } else if ([[fromURL pathExtension] isEqualToString:@"sources"] && [[destinationURL pathExtension] isEqualToString:@"list"]) { //sileo sources format
        NSError *readError;
        NSString *destinationString = [NSString stringWithContentsOfURL:destinationURL encoding:NSUTF8StringEncoding error:&readError];
        NSArray *destinationContents = [destinationString componentsSeparatedByString:@"\n"];
        NSArray *sourcesContents = [[NSString stringWithContentsOfURL:fromURL encoding:NSUTF8StringEncoding error:&readError] componentsSeparatedByString:@"\n\n"];
        if (readError != NULL) {
            NSLog(@"[Zebra] Error while reading: %@", readError.localizedDescription);
            completion(readError);
        }
        
        NSMutableArray *linesToAdd = [NSMutableArray new];
        NSMutableArray *baseURLs = [NSMutableArray new];
        for (NSString *line in destinationContents) {
            NSArray *contents = [line componentsSeparatedByString:@" "];
            if ([contents count] == 0 || [contents count] == 4) continue;
            
            if ([contents[0] isEqualToString:@"deb"]) {
                NSURL *url = [NSURL URLWithString:contents[1]];
                NSString *urlString = [self normalizedURLString:url];
                
                [baseURLs addObject:urlString];
            }
        }
        
        for (NSString *line in sourcesContents) {
            NSMutableDictionary *info = [NSMutableDictionary new];
            [line enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
                if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
                if (pair.count != 2) return;
                NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                info[key] = value;
            }];
            
            if ([[info allKeys] count] == 4) {
                NSURL *url = [NSURL URLWithString:(NSString *)[info objectForKey:@"URIs"]];
                NSString *urlString = [self normalizedURLString:url];
                
                if (![baseURLs containsObject:urlString]) {
                    NSString *converted = [NSString stringWithFormat:@"%@ %@ %@ %@\n", (NSString *)[info objectForKey:@"Types"], (NSString *)[info objectForKey:@"URIs"], (NSString *)[info objectForKey:@"Suites"], (NSString *)[info objectForKey:@"Components"]];
                    [linesToAdd addObject:converted];
                }
            }
        }
        
        if ([linesToAdd count] != 0) {
            NSMutableString *finalContents = [destinationString mutableCopy];
            [finalContents appendString:[NSString stringWithFormat:@"\n# Imported at %@\n", [NSDate date]]];
            for (NSString *line in linesToAdd) {
                NSLog(@"[Zebra] Adding %@ to sources.list", line);
                [finalContents appendString:line];
            }
            
            NSError *writeError;
            [finalContents writeToURL:destinationURL atomically:NO encoding:NSUTF8StringEncoding error:&writeError];
            if (writeError != NULL) {
                NSLog(@"[Zebra] Error while writing to %@: %@", destinationURL, writeError.localizedDescription);
            }
        }
        
        completion(NULL);
    } else {
        NSError *error = [NSError errorWithDomain:NSArgumentDomain code:1337 userInfo:@{NSLocalizedDescriptionKey: @"Both files aren't .list"}];
        completion(error);
    }
    recachingNeeded = YES;
}

@end
