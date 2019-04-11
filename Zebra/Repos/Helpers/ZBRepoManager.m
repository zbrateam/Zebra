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

- (void)addSourceWithURL:(NSString *)urlString response:(void (^)(BOOL success, NSString *error, NSURL *url))respond {
    NSLog(@"[Zebra] Attempting to add %@ to sources list", urlString);
    
    NSURL *sourceURL = [NSURL URLWithString:urlString];
    if (!sourceURL) {
        NSLog(@"[Zebra] Invalid URL: %@", urlString);
        respond(false, [NSString stringWithFormat:@"Invalid URL: %@", urlString], sourceURL);
        return;
    }
    
    [self verifySourceExists:sourceURL completion:^(NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[Zebra] Error verifying repository: %@", error);
            NSURL *url = [(NSURL *)[error.userInfo objectForKey:@"NSErrorFailingURLKey"] URLByDeletingLastPathComponent];
            respond(false, error.localizedDescription, url);
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSURL *url = [httpResponse.URL URLByDeletingLastPathComponent];
        
        if (httpResponse.statusCode != 200) {
            NSString *errorMessage = [NSString stringWithFormat:@"Expected status from url %@, received: %d", url, (int)httpResponse.statusCode];
            NSLog(@"[Zebra] %@", errorMessage);
            respond(false, errorMessage, url);
        }
        
        NSLog(@"[Zebra] Verified source %@", url);
        
        [self addSource:sourceURL completion:^(BOOL success, NSError *addError) {
            if (success) {
                respond(true, NULL, NULL);
            }
            else {
                respond(false, addError.localizedDescription, url);
            }
        }];
    }];
}

- (void)verifySourceExists:(NSURL *)sourceURL completion:(void (^)(NSURLResponse *response, NSError *error))completion {
    NSURL *url = [sourceURL URLByAppendingPathComponent:@"Packages.bz2"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    request.HTTPMethod = @"HEAD";
    
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
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        completion(response, error);
    }];
    [task resume];
}

- (void)addSource:(NSURL *)sourceURL completion:(void (^)(BOOL success, NSError *error))completion {
    NSString *URL = [sourceURL absoluteString];
    NSString *output = @"";
    
//    NSString *contents = [NSString stringWithContentsOfFile:[ZBAppDelegate sourceListLocation] encoding:NSUTF8StringEncoding error:nil];
//    NSLog(@"[Zebra] Previous sources.list\n%@", contents);
    
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
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
    output = [output stringByAppendingFormat:@"deb %@ ./\n", URL];
    
//    NSLog(@"[Zebra] New sources.list\n%@", output);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    
    NSString *filePath;
    if ([[cacheDirectory lastPathComponent] isEqualToString:@"xyz.willy.Zebra"])
        filePath = [cacheDirectory stringByAppendingPathComponent:@"sources.list"];
    else
        filePath = [cacheDirectory stringByAppendingString:@"/xyz.willy.Zebra/sources.list"];
    
    NSError *removeError;
    NSString *listLocation = [ZBAppDelegate sourceListLocation];
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
    
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
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
    if ([[cacheDirectory lastPathComponent] isEqualToString:@"xyz.willy.Zebra"])
        filePath = [cacheDirectory stringByAppendingPathComponent:@"sources.list"];
    else
        filePath = [cacheDirectory stringByAppendingString:@"/xyz.willy.Zebra/sources.list"];
    
    NSError *removeError;
    NSString *listLocation = [ZBAppDelegate sourceListLocation];
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
        
        ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
        [databaseManager deleteRepo:delRepo];
    }
}

- (void)addDebLine:(NSString *)sourceLine {
    NSString *listsLocation = [ZBAppDelegate sourceListLocation];
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
    NSMutableArray *sources = [NSMutableArray new];
    NSString *listsLocation = [ZBAppDelegate sourceListLocation];
    
    NSError *readCydiaError;
    NSArray *cydiaSources = [[NSString stringWithContentsOfFile:@"/var/mobile/Library/Caches/com.saurik.Cydia/sources.list" encoding:NSUTF8StringEncoding error:&readCydiaError] componentsSeparatedByString:@"\n"];
    
    if (readCydiaError != nil) {
        NSLog(@"[Zebra] Error while reading Cydia sources: %@", readCydiaError.localizedDescription);
        return;
    }
    
    for (NSString *line in cydiaSources) {
        if (![sources containsObject:line]) {
            [sources addObject:line];
        }
    }
    
    NSError *readZebraError;
    NSArray *zebraSources = [[NSString stringWithContentsOfFile:listsLocation encoding:NSUTF8StringEncoding error:&readZebraError] componentsSeparatedByString:@"\n"];
    
    if (readZebraError != nil) {
        NSLog(@"[Zebra] Error while reading Zebra sources: %@", readZebraError.localizedDescription);
        return;
    }
    
    for (NSString *line in zebraSources) {
        if (![sources containsObject:line]) {
            [sources addObject:line];
        }
    }
    
    NSString *output = [[sources valueForKey:@"description"] componentsJoinedByString:@"\n"];
    
    NSError *error;
    [output writeToFile:listsLocation atomically:TRUE encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        NSLog(@"[Zebra] Error while writing sources to file: %@", error);
    }
}


@end
