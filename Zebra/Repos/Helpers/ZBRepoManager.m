//
//  ZBRepoManager.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBRepoManager.h"
#import "MobileGestalt.h"
#import <sys/sysctl.h>
#import <UIKit/UIDevice.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Database/ZBDatabaseManager.h>
#import <ZBAppDelegate.h>

@implementation ZBRepoManager

-(void)addSourcesFromString:(NSString *)sourcesString response:(void (^)(BOOL success, NSString *error, NSArray<NSURL *> *failedURLs))respond {
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
                
                dispatch_queue_t sourcesQueue = dispatch_queue_create("xyz.willy.zebra.addsources", NULL);
                
                NSMutableArray<NSString *> *errors = [NSMutableArray array];
                NSMutableArray<NSURL *> *errorURLs = [NSMutableArray array];
                NSMutableArray<NSURL *> *verifiedURLs = [NSMutableArray array];
                
                NSMutableSet<NSURL *> *detectedURLs = [NSMutableSet set];
                
                [detector enumerateMatchesInString:sourcesString options:0 range:NSMakeRange(0, sourcesString.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    if (result.resultType == NSTextCheckingTypeLink) {
                        NSLog(@"[Zebra] Detected url: %@", result.URL);
                        
                        [detectedURLs addObject:result.URL];
                    }
                }];
                
                if (detectedURLs.count == 0) {
                    respond(NO, @"No repository urls detected.", @[]);
                    
                    return;
                }
                
                for (NSURL *detectedURL in detectedURLs) {
                    dispatch_group_enter(group);
                    
                    [strongSelf verifySourceExists:detectedURL completion:^(NSString *responseError, NSURL *failingURL, NSURL *responseURL) {
                        if (responseError) {
                            dispatch_sync(sourcesQueue, ^{
                                [errors addObject:[NSString stringWithFormat:@"%@: %@", failingURL, responseError]];
                                [errorURLs addObject:failingURL];
                                
                                dispatch_group_leave(group);
                            });
                        } else {
                            dispatch_sync(sourcesQueue, ^{
                                [verifiedURLs addObject:detectedURL];
                                
                                dispatch_group_leave(group);
                            });
                        }
                    }];
                }
                
                dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                    typeof(self) strongSelf = weakSelf;
                    
                    if (strongSelf) {
                        __block NSError *addError = nil;
                        
                        [strongSelf addSources:verifiedURLs completion:^(BOOL success, NSError *error) {
                            addError = error;
                        }];
                        
                        if (errors.count > 0) {
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
    __weak typeof(self) weakSelf = self;
    
    [self verifySourceExists:sourceURL completion:^(NSString *responseError, NSURL *failingURL, NSURL *responseURL) {
        typeof(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            if (responseError) {
                respond(NO, responseError, failingURL);
            } else {
                NSLog(@"[Zebra] Verified source %@", responseURL);
                
                [strongSelf addSources:[NSArray arrayWithObject:sourceURL] completion:^(BOOL success, NSError *addError) {
                    if (success) {
                        respond(true, NULL, NULL);
                    }
                    else {
                        respond(false, addError.localizedDescription, responseURL);
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
        respond(false, [NSString stringWithFormat:@"Invalid URL: %@", urlString], sourceURL);
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
    CFStringRef youDID = MGCopyAnswer(CFSTR("UniqueDeviceID"));
    NSString *udid = (__bridge NSString *)youDID;
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    
    NSString *machineIdentifier = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    
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
        
        if (httpResponse.statusCode != 200 || error != NULL ) {
            NSMutableURLRequest *gzRequest = [request copy];
            [gzRequest setURL:[sourceURL URLByAppendingPathComponent:@"Packages.gz"]];
            NSURLSessionDataTask *gzTask = [session dataTaskWithRequest:gzRequest completionHandler:^(NSData * _Nullable gzdata, NSURLResponse * _Nullable gzresponse, NSError * _Nullable gzerror) {
                NSHTTPURLResponse *gzhttpResponse = (NSHTTPURLResponse *)gzresponse;
                if (gzhttpResponse.statusCode != 200 || gzerror != NULL ) {
                    NSString *gzerrorMessage = [NSString stringWithFormat:@"Expected status from url %@, received: %d", url, (int)httpResponse.statusCode];
                    NSLog(@"[Zebra] %@", gzerrorMessage);
                    completion(gzerrorMessage, [sourceURL URLByAppendingPathComponent:@"Packages.gz"], [gzhttpResponse.URL URLByDeletingLastPathComponent]);
                }
                else {
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

- (void)addSources:(NSArray<NSURL *> *)sourceURLs completion:(void (^)(BOOL success, NSError *error))completion {
    NSString *output = @"";
    
    //    NSString *contents = [NSString stringWithContentsOfFile:[ZBAppDelegate sourceListLocation] encoding:NSUTF8StringEncoding error:nil];
    //    NSLog(@"[Zebra] Previous sources.list\n%@", contents);
    
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    for (ZBRepo *source in [databaseManager sources]) {
        if ([source defaultRepo]) {
            if ([[source origin] isEqual:@"Cydia/Telesphoreo"]) {
                output = [output stringByAppendingFormat:@"deb http://apt.saurik.com/ ios/%.2f main\n",kCFCoreFoundationVersionNumber];
            }
            else if ([[source origin] isEqual:@"Bingner/Elucubratus"]) {
                output = [output stringByAppendingFormat:@"deb http://apt.bingner.com/ ios/%.2f main\n",kCFCoreFoundationVersionNumber];
            }
            else {
                NSString *sourceURL = [[source baseURL] stringByDeletingLastPathComponent];
                sourceURL = [sourceURL stringByDeletingLastPathComponent]; //Remove last two path components
                output = [output stringByAppendingFormat:@"deb %@%@/ %@ %@\n", [source isSecure] ? @"https://" : @"http://", sourceURL, [source suite], [source components]];
            }
        }
        else {
            output = [output stringByAppendingFormat:@"deb %@%@ ./\n", [source isSecure] ? @"https://" : @"http://", [source baseURL]];
        }
    }
    
    for (NSURL *sourceURL in sourceURLs) {
        NSString *URL = [sourceURL absoluteString];
        output = [output stringByAppendingFormat:@"deb %@ ./\n", URL];
    }
    
    //    NSLog(@"[Zebra] New sources.list\n%@", output);
    
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
    [output writeToFile:filePath atomically:TRUE encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        NSLog(@"[Zebra] Error while writing sources to file: %@", error);
        completion(false, error);
    }
    else {
        [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:listLocation error:&error];
        if (error != NULL) {
            NSLog(@"[Zebra] Error while moving sources to file: %@", error);
            completion(false, error);
        }
        else {
            completion(true, NULL);
        }
    }
}

- (void)deleteSource:(ZBRepo *)delRepo {
    NSString *output = @"";
    
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    for (ZBRepo *source in [databaseManager sources]) {
        if (![[delRepo baseFileName] isEqualToString:[source baseFileName]]) {
            if ([source defaultRepo]) {
                if ([[source origin] isEqual:@"Cydia/Telesphoreo"]) {
                    output = [output stringByAppendingFormat:@"deb http://apt.saurik.com/ ios/%.2f main\n",kCFCoreFoundationVersionNumber];
                }
                else if ([[source origin] isEqual:@"Bingner/Elucubratus"]) {
                    output = [output stringByAppendingFormat:@"deb http://apt.bingner.com/ ios/%.2f main\n",kCFCoreFoundationVersionNumber];
                }
                else {
                    NSString *sourceURL = [[source baseURL] stringByDeletingLastPathComponent];
                    sourceURL = [sourceURL stringByDeletingLastPathComponent]; //Remove last two path components
                    output = [output stringByAppendingFormat:@"deb %@%@/ %@ %@\n", [source isSecure] ? @"https://" : @"http://", sourceURL, [source suite], [source components]];
                }
            }
            else {
                output = [output stringByAppendingFormat:@"deb %@%@ ./\n", [source isSecure] ? @"https://" : @"http://", [source baseURL]];
            }
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
    [output writeToFile:filePath atomically:TRUE encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        NSLog(@"[Zebra] Error while writing sources to file: %@", error);
    }
    else {
        [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:listLocation error:&error];
        if (error != NULL) {
            NSLog(@"[Zebra] Error while moving sources to file: %@", error);
        }
        
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        [databaseManager deleteRepo:delRepo];
    }
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
    [output writeToFile:listsLocation atomically:TRUE encoding:NSUTF8StringEncoding error:&error];
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

- (void)mergeSourcesFrom:(NSURL *)fromURL into:(NSURL *)destinationURL completion:(void (^)(NSError *error))completion {
    if (![[destinationURL pathExtension] isEqualToString:@"list"] || ![[destinationURL pathExtension] isEqualToString:@"list"]) { //Check to be sure both urls of are type .list
        NSError *error = [NSError errorWithDomain:NSArgumentDomain code:1337 userInfo:@{NSLocalizedDescriptionKey: @"Both files aren't .list"}];
        completion(error);
    }
    
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
        if ([contents count] == 0 || [contents count] == 4) continue;
        
        if ([contents[0] isEqualToString:@"deb"]) {
            NSURL *url = [NSURL URLWithString:contents[1]];
            NSString *urlString = [[contents[1] stringByReplacingOccurrencesOfString:[url scheme] withString:[url scheme]] substringFromIndex:3]; //Remove http:// or https:// from url
            
            [baseURLs addObject:urlString];
        }
    }
    
    for (NSString *line in sourcesContents) {
        NSArray *contents = [line componentsSeparatedByString:@" "];
        if ([contents count] == 0 || [contents count] == 4) continue;
        
        if ([contents[0] isEqualToString:@"deb"]) {
            NSURL *url = [NSURL URLWithString:contents[1]];
            NSString *urlString = [[contents[1] stringByReplacingOccurrencesOfString:[url scheme] withString:[url scheme]] substringFromIndex:3]; //Remove http:// or https:// from url
            
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
        [finalContents writeToURL:destinationURL atomically:false encoding:NSUTF8StringEncoding error:&writeError];
        if (writeError != NULL) {
            NSLog(@"[Zebra] Error while writing to %@: %@", destinationURL, writeError.localizedDescription);
        }
    }
    
    completion(NULL);
}

@end
