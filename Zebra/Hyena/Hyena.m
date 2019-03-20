//
//  Hyena.m
//  Zebra
//
//  Created by Wilson Styres on 3/20/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "Hyena.h"
#import <UIKit/UIDevice.h>
#import <sys/sysctl.h>

@implementation Hyena

- (id)initWithSourceListPath:(NSString *)trail {
    self = [super init];
    
    if (self) {
        repos = [self reposFromSourcePath:trail];
        NSLog(@"Init Repos: %@", repos);
    }
    
    return self;
}

- (NSArray *)reposFromSourcePath:(NSString *)path {
    NSMutableArray *repos = [NSMutableArray new];
    
    NSError *sourceListReadError;
    NSString *sourceList = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&sourceListReadError];
    NSArray *debLines = [sourceList componentsSeparatedByString:@"\n"];
    
    for (NSString *line in debLines) {
        if (![line isEqual:@""]) {
            NSArray *baseURL = [self baseURLFromDebLine:line];
            [repos addObject:baseURL];
        }
    }
    
    return (NSArray *)repos;
}

- (NSArray *)baseURLFromDebLine:(NSString *)debLine {
    NSArray *urlComponents;
    
    NSArray *components = [debLine componentsSeparatedByString:@" "];
    if ([components count] > 3) { //Distribution repo, we get it, you're cool
        NSString *baseURL = components[1];
        NSString *suite = components[2];
        NSString *component = components[3];
        
        urlComponents = @[baseURL, suite, component];
    }
    else { //Normal, non-weird repo
        NSString *baseURL = components[1];
        
        urlComponents = @[baseURL];
    }
    
    return urlComponents;
}

- (void)downloadReposWithCompletion:(void (^)(BOOL success))completion {
    [self downloadRepos:repos completion:^(BOOL success) {
        completion(success);
    }];
}

//[[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @1, @"message": @"Importing Remote APT Repositories...\n"}];
- (void)downloadRepos:(NSArray *)repos completion:(void (^)(BOOL success))completion {
    int i = 0;
    NSLog(@"Download repos!!!! %@", repos);
    for (NSArray *repo in repos) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"repoStatusUpdate" object:self userInfo:@{@"rowID": @(i), @"busy": @YES}];
        
        NSLog(@"Downloading %@", repo[0]);
        if ([repo count] == 3) { //dist
            [self downloadFromURL:[NSString stringWithFormat:@"%@dists/%@/", repo[0], repo[1]] file:@"Release" row:i];
            [self downloadFromURL:[NSString stringWithFormat:@"%@dists/%@/main/binary-iphoneos-arm/", repo[0], repo[1]] file:@"Packages.bz2" row:i];
        }
        else { //reg
            [self downloadFromURL:repo[0] file:@"Release" row:i];
            [self downloadFromURL:repo[0] file:@"Packages.bz2" row:i];
        }
        NSLog(@"Done %@", repo[0]);
        i++;
    }
    completion(true);
}

- (void)downloadFromURL:(NSString *)baseURL file:(NSString *)filename row:(int)i {
    NSURL *url = [[NSURL URLWithString:baseURL] URLByAppendingPathComponent:filename];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSString *version = [[UIDevice currentDevice] systemVersion];
    NSString *udid = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    //    CFStringRef youDID = MGCopyAnswer(CFSTR("UniqueDeviceID"));
    //    NSString *udid = (__bridge NSString *)youDID;
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    
    NSString *machineIdentifier = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    
    //@"If-Modified-Since": @"Tue, 19 Mar 2019 18:33:49 GMT, "
    configuration.HTTPAdditionalHeaders = @{@"X-Cydia-ID" : udid, @"User-Agent" : @"Telesphoreo APT-HTTP/1.0.592", @"X-Firmware": version, @"X-Unique-ID" : udid, @"X-Machine" : machineIdentifier};
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURLSessionTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        
        NSString *saveName = [NSString stringWithFormat:@"%@_%@", [[url absoluteString] stringByReplacingOccurrencesOfString:@"/" withString:@"~"], filename];
        NSString *finalPath = [documentsPath stringByAppendingPathComponent:saveName];
        
        BOOL success;
        NSError *fileManagerError;
        if ([fileManager fileExistsAtPath:finalPath]) {
            success = [fileManager removeItemAtPath:finalPath error:&fileManagerError];
            NSAssert(success, @"removeItemAtPath error: %@", fileManagerError);
        }
        
        success = [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:finalPath] error:&fileManagerError];
        NSAssert(success, @"moveItemAtURL error: %@", fileManagerError);
        
       [[NSNotificationCenter defaultCenter] postNotificationName:@"repoStatusUpdate" object:self userInfo:@{@"rowID": @(i), @"busy": @NO}];
    }];
    
    [downloadTask resume];
}

@end
