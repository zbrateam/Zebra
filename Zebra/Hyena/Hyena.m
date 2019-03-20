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
#import <bzlib.h>

@implementation Hyena

- (id)initWithSourceListPath:(NSString *)trail {
    self = [super init];
    
    if (self) {
        repos = [self reposFromSourcePath:trail];
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

- (void)downloadReposWithCompletion:(void (^)(NSArray *filenames, BOOL success))completion {
    NSLog(@"Repos: %@", repos);
    [self downloadRepos:repos completion:^(NSArray *filenames, BOOL success) {
        NSLog(@"Filenames: %@", filenames);
        completion(filenames, true);
    }];
}

//[[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @1, @"message": @"Importing Remote APT Repositories...\n"}];
- (void)downloadRepos:(NSArray *)repos completion:(void (^)(NSArray *filenames, BOOL success))completion {
    
    NSMutableArray *fnms = [NSMutableArray new];
    dispatch_group_t downloadGroup = dispatch_group_create();
    for (int i = 0; i < repos.count; i++) {
        
        NSArray *repo = repos[i];
        
        //            [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"rowID": @(i), @"busy": @YES}];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @1, @"message": [NSString stringWithFormat:@"Downloading %@\n", repo[0]]}];
        NSLog(@"[Hyena] Downloading %@", repo[0]);
        if ([repo count] == 3) { //dist
            dispatch_group_async(downloadGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                dispatch_group_enter(downloadGroup);
                [self downloadFromURL:[NSString stringWithFormat:@"%@dists/%@/", repo[0], repo[1]] file:@"Release" row:i completion:^(NSString *releaseFilename, BOOL success) {
                    [fnms addObject:releaseFilename];
                    [self downloadFromURL:[NSString stringWithFormat:@"%@dists/%@/main/binary-iphoneos-arm/", repo[0], repo[1]] file:@"Packages.bz2" row:i completion:^(NSString *filename, BOOL success) {
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @0, @"message": [NSString stringWithFormat:@"Completed %@\n", repo[0]]}];
                        NSLog(@"[Hyena] Completed %@", repo[0]);
                        
                        dispatch_group_leave(downloadGroup);
                    }];
                }];
            });
        }
        else { //reg
            dispatch_group_async(downloadGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                dispatch_group_enter(downloadGroup);
                [self downloadFromURL:repo[0] file:@"Release" row:i completion:^(NSString *releaseFilename, BOOL success) {
                    [fnms addObject:releaseFilename];
                    [self downloadFromURL:repo[0] file:@"Packages.bz2" row:i completion:^(NSString *filename, BOOL success) {
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"databaseStatusUpdate" object:self userInfo:@{@"level": @0, @"message": [NSString stringWithFormat:@"Completed %@\n", repo[0]]}];
                        NSLog(@"[Hyena] Completed %@", repo[0]);
                        
                        dispatch_group_leave(downloadGroup);
                    }];
                }];
            });
        }
    }
    
    dispatch_group_wait(downloadGroup, DISPATCH_TIME_FOREVER);
//    dispatch_group_notify(downloadGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        NSLog(@"[Hyena] Done");
        completion(fnms, true);
//    });
}

- (void)downloadFromURL:(NSString *)baseURL file:(NSString *)filename row:(int)i completion:(void (^)(NSString *filename, BOOL success))completion {
    NSURL *base = [NSURL URLWithString:baseURL];
    NSURL *url = [base URLByAppendingPathComponent:filename];
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
        //NSLog(@"Compltion: %@, Response %@, Error %@", location, response.URL, error);
        //this is a mess, probably could do this beter latter
        NSString *schemeless = [[base absoluteString]stringByReplacingOccurrencesOfString:[url scheme] withString:@""];
        NSString *safe = [[schemeless substringFromIndex:3] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        NSString *saveName;
        
        if ([baseURL rangeOfString:@"dists"].location == NSNotFound) {
             saveName = [NSString stringWithFormat:@"%@._%@", safe, filename];
        }
        else {
             saveName = [NSString stringWithFormat:@"%@%@", safe, filename];
        }
        
        NSString *finalPath = [documentsPath stringByAppendingPathComponent:saveName];
        
        BOOL success;
        NSError *fileManagerError;
        if ([fileManager fileExistsAtPath:finalPath]) {
            success = [fileManager removeItemAtPath:finalPath error:&fileManagerError];
            NSAssert(success, @"removeItemAtPath error: %@", fileManagerError);
        }
        
        success = [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:finalPath] error:&fileManagerError];
        NSAssert(success, @"moveItemAtURL error: %@", fileManagerError);
        
        if ([[filename pathExtension] isEqual:@"bz2"]) {
            NSLog(@"Location: %@", finalPath);
            FILE *f = fopen([finalPath UTF8String], "r");
            FILE *output = fopen([[finalPath stringByDeletingPathExtension] UTF8String], "w");
            
            int bzError;
            BZFILE *bzf;
            char buf[4096];
            
            bzf = BZ2_bzReadOpen(&bzError, f, 0, 0, NULL, 0);
            if (bzError != BZ_OK) {
                fprintf(stderr, "[Hyena] E: BZ2_bzReadOpen: %d\n", bzError);
            }
            fprintf(stderr, "[Hyena] E: BZ2_bzReadOpen: %d\n", bzError);
            
            while (bzError == BZ_OK) {
                int nread = BZ2_bzRead(&bzError, bzf, buf, sizeof buf);
                if (bzError == BZ_OK || bzError == BZ_STREAM_END) {
                    size_t nwritten = fwrite(buf, 1, nread, output);
                    if (nwritten != (size_t) nread) {
                        fprintf(stderr, "[Hyena] E: short write\n");
                    }
                }
            }
            
            if (bzError != BZ_STREAM_END) {
                fprintf(stderr, "[Hyena] E: bzip error after read: %d\n", bzError);
            }
            fprintf(stderr, "[Hyena] E: BZ2_bzReadOpen: %d\n", bzError);
            
            BZ2_bzReadClose(&bzError, bzf);
            fclose(f);
            fclose(output);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"repoStatusUpdate" object:self userInfo:@{@"rowID": @(i), @"busy": @NO}];
        completion(finalPath, true);
    }];
    
    [downloadTask resume];
}

@end
