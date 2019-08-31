//
//  ZBRepoManager.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBRepoManager.h"
#import <UIKit/UIDevice.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Database/ZBDatabaseManager.h>
#import <ZBAppDelegate.h>
#import <ZBDevice.h>

@interface ZBRepoManager () {
    NSMutableArray<NSURL *> *verifiedURLs;
    NSMutableDictionary <NSNumber *, ZBRepo *> *repos;
    BOOL recachingNeeded;
}
@end

@implementation ZBRepoManager

+ (id)sharedInstance {
    static ZBRepoManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBRepoManager new];
        instance->recachingNeeded = YES;
    });
    return instance;
}

- (void)needRecaching {
    recachingNeeded = YES;
}

- (NSMutableDictionary <NSNumber *, ZBRepo *> *)repos {
    if (recachingNeeded) {
        recachingNeeded = NO;
        repos = [NSMutableDictionary new];
        NSString *query = @"SELECT * FROM REPOS;";
        
        sqlite3 *database;
        sqlite3_open([[ZBAppDelegate databaseLocation] UTF8String], &database);
        
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ZBRepo *source = [[ZBRepo alloc] initWithSQLiteStatement:statement];
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

- (NSArray <NSURL *> *)verifiedURLs {
    return verifiedURLs;
}

+ (NSArray <NSString *> *)knownDistURLs {
    static NSArray *urls = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        urls = @[@"apt.thebigboss.org/",
            @"apt.modmyi.com/",
            @"apt.saurik.com/",
            @"cydia.zodttd.com/"];
    });
    return urls;
}

+ (NSArray <NSString *> *)knownDebLines {
    static NSArray *lines = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lines = @[
            @"deb http://apt.thebigboss.org/repofiles/cydia/ stable main\n",
            @"deb http://apt.modmyi.com/ stable main\n",
            [NSString stringWithFormat:@"deb http://apt.saurik.com/ ios/%.2f main\n", kCFCoreFoundationVersionNumber],
            @"deb http://cydia.zodttd.com/repo/cydia/ stable main\n"
        ];
    });
    return lines;
}

- (NSString *)knownDebLineFromURLString:(NSString *)urlString {
    int index = 0;
    for (NSString *knownURL in [[self class] knownDistURLs]) {
        if ([urlString containsString:knownURL]) {
            return [[self class] knownDebLines][index];
        }
        ++index;
    }
    return nil;
}

- (void)addSourcesFromString:(NSString *)sourcesString response:(void (^)(BOOL success, NSString *error, NSArray<NSURL *> *failedURLs))respond {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            NSError *detectorError = nil;
            NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&detectorError];
            
            if (detectorError) {
                respond(NO, detectorError.localizedDescription, [NSArray array]);
            } else {
                dispatch_group_t group = dispatch_group_create();
                
                dispatch_queue_t sourcesQueue = dispatch_queue_create("xyz.willy.Zebra.addsources", NULL);
                
                NSMutableArray<NSString *> *errors = [NSMutableArray array];
                NSMutableArray<NSURL *> *errorURLs = [NSMutableArray array];
                self->verifiedURLs = [NSMutableArray new];
                
                NSMutableSet<NSURL *> *detectedURLs = [NSMutableSet set];
                
                [detector enumerateMatchesInString:sourcesString options:0 range:NSMakeRange(0, sourcesString.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    if (result.resultType == NSTextCheckingTypeLink) {
                        NSURL *url = [self normalizedURL:result.URL];
                        NSLog(@"[Zebra] Detected url: %@", url);
                        
                        [detectedURLs addObject:url];
                    }
                }];
                
                if (detectedURLs.count == 0) {
                    respond(NO, @"No repository urls detected.", @[]);
                    return;
                }
                
                NSError *readError;
                NSString *sourcesList = [NSString stringWithContentsOfURL:[ZBAppDelegate sourcesListURL] encoding:NSUTF8StringEncoding error:&readError];
                NSArray *sourcesListContents = [sourcesList componentsSeparatedByString:@"\n"];
                
                if (readError != NULL) {
                    // rip
                    respond(NO, [NSString stringWithFormat:@"%@ (%@)", readError.localizedDescription, sourcesList], @[]);
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
                        NSString *debLine = [self knownDebLineFromURLString:urlString];
                        if (debLine) {
                            [self addDebLine:debLine];
                            respond(YES, nil, nil);
                        } else {
                            [strongSelf verifySourceExists:detectedURL completion:^(NSString *responseError, NSURL *failingURL, NSURL *responseURL) {
                                if (responseError) {
                                    dispatch_sync(sourcesQueue, ^{
                                        [errors addObject:[NSString stringWithFormat:@"%@: %@", failingURL, responseError]];
                                        [errorURLs addObject:failingURL];
                                        
                                        dispatch_group_leave(group);
                                    });
                                } else {
                                    dispatch_sync(sourcesQueue, ^{
                                        [self->verifiedURLs addObject:detectedURL];
                                        
                                        dispatch_group_leave(group);
                                    });
                                }
                            }];
                        }
                    }
                }
                
                dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                    typeof(self) strongSelf = weakSelf;
                    
                    if (strongSelf) {
                        if ([self->verifiedURLs count] == 0 && [errorURLs count] == 0) {
                            respond(NO, @"You have already added these repositories.", @[]);
                        } else {
                            __block NSError *addError = nil;
                            
                            [strongSelf addSources:self->verifiedURLs completion:^(BOOL success, NSError *error) {
                                addError = error;
                            }];
                            
                            if (errors.count) {
                                NSString *errorMessage;
                                
                                if (errors.count == 1) {
                                    errorMessage = [NSString stringWithFormat:@"Error verifying repository:\n%@", [errors componentsJoinedByString:@"\n"]];
                                } else {
                                    errorMessage = [NSString stringWithFormat:@"Error verifying repositories:\n%@", [errors componentsJoinedByString:@"\n"]];
                                }
                                if (addError) {
                                    errorMessage = [NSString stringWithFormat:@"%@\n%@", addError.localizedDescription, errorMessage];
                                }
                                respond(NO, errorMessage, errorURLs);
                            } else {
                                respond(YES, nil, nil);
                            }
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            respond(NO, @"Unknown error.", @[]);
                        });
                    }
                });
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                respond(NO, @"Unknown error.", @[]);
            });
        }
    });
}

- (void)addSourceWithURL:(NSURL *)sourceURL response:(void (^)(BOOL success, NSString *error, NSURL *url))respond {
    [self verifySourceExists:sourceURL completion:^(NSString *responseError, NSURL *failingURL, NSURL *responseURL) {
        
        if (self) {
            if (responseError) {
                respond(NO, responseError, failingURL);
            } else {
                if (responseURL == nil) {
                    responseURL = sourceURL;
                }
                NSLog(@"[Zebra] Verified source %@", responseURL);
                
                [self addSources:[NSArray arrayWithObject:sourceURL] completion:^(BOOL success, NSError *addError) {
                    if (success) {
                        respond(YES, NULL, NULL);
                    } else {
                        respond(NO, addError.localizedDescription, responseURL);
                    }
                }];
            }
        } else {
            respond(NO, @"Unknown error.", responseURL);
        }
    }];
}

- (void)addSourceWithString:(NSString *)urlString response:(void (^)(BOOL success, NSString *error, NSURL *url))respond {
    NSLog(@"[Zebra] Attempting to add %@ to sources list", urlString);
    
    NSURL *sourceURL = [NSURL URLWithString:urlString];
    if (!sourceURL) {
        NSLog(@"[Zebra] Invalid URL: %@", urlString);
        respond(NO, [NSString stringWithFormat:@"Invalid URL: %@", urlString], sourceURL);
        return;
    }
    
    [self addSourceWithURL:sourceURL response:respond];
}

- (void)verifySourceExists:(NSURL *)sourceURL completion:(void (^)(NSString *responseError, NSURL *failingURL, NSURL *responseURL))completion {
    NSURL *url = [sourceURL URLByAppendingPathComponent:@"Packages.bz2"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    
    NSString *version = [[UIDevice currentDevice] systemVersion];
    NSString *udid = [ZBDevice UDID];
    NSString *machineIdentifier = [ZBDevice machineID];
    
    [request setValue:@"Telesphoreo APT-HTTP/1.0.592" forHTTPHeaderField:@"User-Agent"];
    [request setValue:version forHTTPHeaderField:@"X-Firmware"];
    [request setValue:udid forHTTPHeaderField:@"X-Unique-ID"];
    [request setValue:machineIdentifier forHTTPHeaderField:@"X-Machine"];
    
    if ([[url scheme] isEqualToString:@"https"]) {
        [request setValue:udid forHTTPHeaderField:@"X-Cydia-Id"];
    }
    
    [request setHTTPMethod:@"HEAD"];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSURL *responseURL = [httpResponse.URL URLByDeletingLastPathComponent];
        if (httpResponse.statusCode != 200 || error != NULL) {
            NSMutableURLRequest *gzRequest = [request copy];
            [gzRequest setURL:[sourceURL URLByAppendingPathComponent:@"Packages.gz"]];
            NSURLSessionDataTask *gzTask = [session dataTaskWithRequest:gzRequest completionHandler:^(NSData * _Nullable gzdata, NSURLResponse * _Nullable gzresponse, NSError * _Nullable gzerror) {
                NSHTTPURLResponse *gzhttpResponse = (NSHTTPURLResponse *)gzresponse;
                if (gzhttpResponse.statusCode != 200 || gzerror != NULL) {
                    NSMutableURLRequest *pureRequest = [request copy];
                    [pureRequest setURL:[sourceURL URLByAppendingPathComponent:@"Packages"]];
                    NSURLSessionDataTask *pureTask = [session dataTaskWithRequest:pureRequest completionHandler:^(NSData * _Nullable pureData, NSURLResponse * _Nullable pureResponse, NSError * _Nullable pureError) {
                        NSHTTPURLResponse * _Nullable pureHttpResponse = (NSHTTPURLResponse *)pureResponse;
                        if (pureHttpResponse.statusCode != 200 || pureError != NULL) {
                            NSString *pureErrorMessage = [NSString stringWithFormat:@"Expected status from url %@, received: %d", url, (int)httpResponse.statusCode];
                            NSLog(@"[Zebra] %@", pureErrorMessage);
                            completion(pureErrorMessage, [sourceURL URLByAppendingPathComponent:@"Packages"], [pureHttpResponse.URL URLByDeletingLastPathComponent]);
                        } else {
                            completion(nil, nil, responseURL);
                        }
                    }];
                    [pureTask resume];
                } else {
                    completion(nil, nil, responseURL);
                }
            }];
            [gzTask resume];
        } 
        else {
            completion(nil, nil, responseURL);
        }
    }];
    [task resume];
}

- (NSString *)debLineFromRepo:(ZBRepo *)repo {
    NSMutableString *output = [NSMutableString string];
    if ([repo defaultRepo]) {
        NSString *debLine = [self knownDebLineFromURLString:[repo baseURL]];
        if (debLine) {
            [output appendString:debLine];
        } else {
            NSString *repoURL = [[repo baseURL] stringByDeletingLastPathComponent];
            repoURL = [repoURL stringByDeletingLastPathComponent]; // Remove last two path components
            [output appendFormat:@"deb %@%@/ %@ %@\n", [repo isSecure] ? @"https://" : @"http://", repoURL, [repo suite], [repo components]];
        }
    } else {
        [output appendFormat:@"deb %@%@ ./\n", [repo isSecure] ? @"https://" : @"http://", [repo baseURL]];
    }
    return output;
}

- (void)addSources:(NSArray<NSURL *> *)sourceURLs completion:(void (^)(BOOL success, NSError *error))completion {
    NSMutableString *output = [NSMutableString string];
    
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    for (ZBRepo *repo in [databaseManager repos]) {
        [output appendString:[self debLineFromRepo:repo]];
    }
    
    for (NSURL *sourceURL in sourceURLs) {
        NSString *URL = [sourceURL absoluteString];
        [output appendFormat:@"deb %@ ./\n", URL];
    }
        
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    
    NSString *filePath;
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if ([[cacheDirectory lastPathComponent] isEqualToString:bundleID])
        filePath = [cacheDirectory stringByAppendingPathComponent:@"sources.list"];
    else
        filePath = [cacheDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@/sources.list", bundleID]];
    
    NSError *removeError;
    NSString *listLocation = [ZBAppDelegate sourcesListPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:listLocation]) {
        [[NSFileManager defaultManager] removeItemAtPath:listLocation error:&removeError];
    }
    
    NSError *error;
    [output writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        NSLog(@"[Zebra] Error while writing sources to file: %@", error);
        completion(NO, error);
    } else {
        [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:listLocation error:&error];
        if (error != NULL) {
            NSLog(@"[Zebra] Error while moving sources to file: %@", error);
            completion(NO, error);
        } else {
            completion(YES, NULL);
        }
    }
    recachingNeeded = YES;
}

- (void)deleteSource:(ZBRepo *)delRepo {
    NSMutableString *output = [NSMutableString string];
    
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    for (ZBRepo *repo in [databaseManager repos]) {
        if (![[delRepo baseFileName] isEqualToString:[repo baseFileName]]) {
            [output appendString:[self debLineFromRepo:repo]];
        }
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    
    NSString *filePath;
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if ([[cacheDirectory lastPathComponent] isEqualToString:bundleID])
        filePath = [cacheDirectory stringByAppendingPathComponent:@"sources.list"];
    else
        filePath = [cacheDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@/sources.list", bundleID]];
    
    NSError *removeError;
    NSString *listLocation = [ZBAppDelegate sourcesListPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:listLocation]) {
        [[NSFileManager defaultManager] removeItemAtPath:listLocation error:&removeError];
    }
    
    NSError *error;
    [output writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        NSLog(@"[Zebra] Error while writing sources to file: %@", error);
    } else {
        [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:listLocation error:&error];
        if (error != NULL) {
            NSLog(@"[Zebra] Error while moving sources to file: %@", error);
        }
        
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        [databaseManager deleteRepo:delRepo];
    }
    recachingNeeded = YES;
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
        if (error != NULL) {
            NSLog(@"[Zebra] Error merging sources: %@", error);
        }
    }];
}

- (void)transferFromSileo {
    NSURL *listsURL = [ZBAppDelegate sourcesListURL];
    NSURL *sileoListsURL = [NSURL URLWithString:@"file:///etc/apt/sources.list.d/sileo.sources"];
    
    [self mergeSourcesFrom:sileoListsURL into:listsURL completion:^(NSError * _Nonnull error) {
        if (error != NULL) {
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
