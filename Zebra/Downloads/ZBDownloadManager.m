//
//  ZBDownloadManager.m
//  Zebra
//
//  Created by Wilson Styres on 4/14/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBDownloadManager.h"

#import <UIKit/UIDevice.h>
#import <sys/sysctl.h>

#import <Queue/ZBQueue.h>
#import <ZBAppDelegate.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Repos/Helpers/ZBRepo.h>

#import <bzlib.h>
#import <zlib.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface ZBDownloadManager () {
    BOOL ignore;
    int tasks;
}
@end

@implementation ZBDownloadManager

@synthesize repos;
@synthesize queue;
@synthesize downloadDelegate;
@synthesize filenames;

- (id)init {
    self = [super init];
    
    if (self) {
        queue = [ZBQueue sharedInstance];
        filenames = [NSMutableDictionary new];
    }
    
    return self;
}

- (id)initWithSourceListPath:(NSString *)trail {
    self = [super init];
    
    if (self) {
        repos = [self reposFromSourcePath:trail];
        
        queue = [ZBQueue sharedInstance];
        filenames = [NSMutableDictionary new];
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
            if ([line characterAtIndex:0] == '#') continue;
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

- (NSDictionary *)headers {
    return [self headersForFile:NULL];
}

- (NSDictionary *)headersForFile:(NSString *)path {
    NSString *version = [[UIDevice currentDevice] systemVersion];
    NSString *udid = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    
    NSString *machineIdentifier = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    
    if (path == NULL) {
        return @{@"X-Cydia-ID" : udid, @"User-Agent" : @"Telesphoreo APT-HTTP/1.0.592", @"X-Firmware": version, @"X-Unique-ID" : udid, @"X-Machine" : machineIdentifier};
    }
    else {
        NSError *fileError;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&fileError];
        NSDate *date = fileError != nil ? [NSDate distantPast] : [attributes fileModificationDate];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        [formatter setTimeZone:gmt];
        [formatter setDateFormat:@"E, d MMM yyyy HH:mm:ss"];
        
        NSString *modificationDate = [NSString stringWithFormat:@"%@ GMT", [formatter stringFromDate:date]];
        
        return @{@"If-Modified-Since": modificationDate, @"X-Cydia-ID" : udid, @"User-Agent" : @"Telesphoreo APT-HTTP/1.0.592", @"X-Firmware": version, @"X-Unique-ID" : udid, @"X-Machine" : machineIdentifier};
    }
}

- (void)downloadRepos:(NSArray <ZBRepo *> *)repos ignoreCaching:(BOOL)ignore {
    self->ignore = ignore;
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = ignore ? [self headers] : [self headersForFile:@"file"];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    for (NSArray *repo in self.repos) {
        BOOL dist = [repo count] == 3;
        NSURL *baseURL = dist ? [NSURL URLWithString:[NSString stringWithFormat:@"%@dists/%@/", repo[0], repo[1]]] : [NSURL URLWithString:repo[0]];
        NSURL *releaseURL = [baseURL URLByAppendingPathComponent:@"Release"];
        NSURL *packagesURL = dist ? [baseURL URLByAppendingPathComponent:@"main/binary-iphoneos-arm/Packages.bz2"] : [baseURL URLByAppendingPathComponent:@"Packages.bz2"];
        
        NSURLSessionTask *releaseTask = [session downloadTaskWithURL:releaseURL];
        tasks++;
        [releaseTask resume];
        
        NSURLSessionTask *packagesTask = [session downloadTaskWithURL:packagesURL];
        tasks++;
        [packagesTask resume];

        NSString *schemeless = [[baseURL absoluteString] stringByReplacingOccurrencesOfString:[baseURL scheme] withString:@""];
        NSString *safe = [[schemeless substringFromIndex:3] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        NSString *saveName = [NSString stringWithFormat:[[baseURL absoluteString] rangeOfString:@"dists"].location == NSNotFound ? @"%@._%@" : @"%@%@", safe, @"Release"];
        NSString *baseFileName = [self baseFileNameFromFullPath:saveName];
        
        [downloadDelegate predator:self startedDownloadForFile:baseFileName];
    }
}

- (void)downloadFromURL:(NSURL *)url ignoreCaching:(BOOL)ignore {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = ignore ? [self headers] : [self headersForFile:@"file"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    NSURLSessionTask *task = [session downloadTaskWithURL:url];
    tasks++;
    [task resume];
    
    NSString *schemeless = [[url absoluteString] stringByReplacingOccurrencesOfString:[url scheme] withString:@""];
    NSString *safe = [[schemeless substringFromIndex:3] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *saveName = [NSString stringWithFormat:[[url absoluteString] rangeOfString:@"dists"].location == NSNotFound ? @"%@._%@" : @"%@%@", safe, @"_Release"];
    NSString *baseFileName = [self baseFileNameFromFullPath:saveName];
    
    [downloadDelegate predator:self startedDownloadForFile:baseFileName];
}

- (void)downloadRepo:(ZBRepo *)repo {
    [self downloadRepos:@[repo] ignoreCaching:false];
}

- (void)downloadReposAndIgnoreCaching:(BOOL)ignore {
    [self downloadRepos:repos ignoreCaching:ignore];
}

- (void)downloadPackages:(NSArray <ZBPackage *> *)packages {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = [self headers];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    for (ZBPackage *package in packages) {
        ZBRepo *repo = [package repo];
        
        if (repo == NULL) {
            break;
        }
        
        NSString *baseURL = [repo isSecure] ? [@"https://" stringByAppendingString:[repo baseURL]] : [@"http://" stringByAppendingString:[repo baseURL]];
        NSString *filename = [package filename];
        
        NSArray *comps = [baseURL componentsSeparatedByString:@"dists"];
        NSURL *base = [NSURL URLWithString:comps[0]];
        NSURL *url = [base URLByAppendingPathComponent:filename];
    
        NSURLSessionTask *downloadTask = [session downloadTaskWithURL:url];
        tasks++;
        
        [downloadDelegate predator:self startedDownloadForFile:filename];
        [downloadTask resume];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)[downloadTask response];
    NSInteger responseCode = [httpResponse statusCode];
    NSURL *url = [[downloadTask originalRequest] URL];
    NSString *filename = [url lastPathComponent];
    if (responseCode != 200 && responseCode != 304) { //Handle error code
        if ([[filename lastPathComponent] containsString:@".bz2"]) { //Try to download .gz
            [self downloadFromURL:[[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"Packages.gz"] ignoreCaching:self->ignore];
        }
        else {
            if (![filename isEqualToString:@"Release"]) {
                if (responseCode >= 400 && [[[httpResponse allHeaderFields] objectForKey:@"Content-Type"] isEqualToString:@"text/plain"]) {
                    //Allows custom error message to be displayed by the repository using the body
                    NSError *readError;
                    NSString *contents = [NSString stringWithContentsOfURL:location encoding:NSUTF8StringEncoding error:&readError];
                    
                    if (readError) {
                        NSLog(@"%@", readError);
                        [downloadDelegate predator:self finishedDownloadForFile:[[[downloadTask originalRequest] URL] lastPathComponent] withError:readError];
                    }
                    else {
                        NSLog(@"Response: %@", contents);
                        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:responseCode userInfo:@{NSLocalizedDescriptionKey: contents}];
                        [downloadDelegate predator:self finishedDownloadForFile:[[[downloadTask originalRequest] URL] lastPathComponent] withError:error];
                    }
                }
                else {
                    NSString *reasonPhrase = (__bridge_transfer NSString *)CFHTTPMessageCopyResponseStatusLine(CFHTTPMessageCreateResponse(kCFAllocatorDefault, [httpResponse statusCode], NULL, kCFHTTPVersion1_1)); //🤮
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:responseCode userInfo:@{NSLocalizedDescriptionKey: [reasonPhrase stringByAppendingString:[NSString stringWithFormat:@": %@\n", filename]]}];
                    if ([[filename lastPathComponent] containsString:@".deb"]) {
                        [self cancelAllTasksForSession:session];
                    }
                    
                    if ([[[[downloadTask originalRequest] URL] lastPathComponent] containsString:@".deb"]) {
                        [self->downloadDelegate predator:self finishedDownloadForFile:[[[downloadTask originalRequest] URL] lastPathComponent] withError:error];
                    }
                    else {
                        [self->downloadDelegate predator:self finishedDownloadForFile:[[[downloadTask originalRequest] URL] absoluteString] withError:error];
                    }
                }
            }
        }
    }
    else { //Download success
        if ([[filename lastPathComponent] containsString:@".deb"]) {
            NSString *debsPath = [ZBAppDelegate debsLocation];
            NSString *filename = [[[downloadTask originalRequest] URL] lastPathComponent];
            NSString *finalPath = [debsPath stringByAppendingPathComponent:filename];
            
            [self moveFileFromLocation:location to:finalPath completion:^(BOOL success, NSError *error) {
                if (!success && error != NULL) {
                    [self cancelAllTasksForSession:session];
                    NSLog(@"[Zebra] Error while moving file at %@ to %@: %@", location, finalPath, error.localizedDescription);
                }
                else {
                    [self addFile:finalPath toArray:@"debs"];
                }
            }];
        }
        else if ([[filename lastPathComponent] containsString:@".gz"]) {
            if (responseCode == 304) {
                [downloadDelegate postStatusUpdate:[NSString stringWithFormat:@"%@ hasn't been modified", [url host]] atLevel:ZBLogLevelDescript];
            }
            else {
                NSString *listsPath = [ZBAppDelegate listsLocation];
                NSString *schemeless = [[[url URLByDeletingLastPathComponent] absoluteString] stringByReplacingOccurrencesOfString:[url scheme] withString:@""];
                NSString *safe = [[schemeless substringFromIndex:3] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                NSString *saveName = [NSString stringWithFormat:[[url absoluteString] rangeOfString:@"dists"].location == NSNotFound ? @"%@._%@" : @"%@%@", safe, filename];
                NSString *finalPath = [listsPath stringByAppendingPathComponent:saveName];
                
                [self moveFileFromLocation:location to:finalPath completion:^(BOOL success, NSError *error) {
                    if (!success && error != NULL) {
                        NSLog(@"[Zebra] Error while moving file at %@ to %@: %@", location, finalPath, error.localizedDescription);
                        [self->downloadDelegate predator:self finishedDownloadForFile:[self baseFileNameFromFullPath:finalPath] withError:error];
                    }
                    else {
                        NSData *data = [NSData dataWithContentsOfFile:finalPath];
                        
                        z_stream stream;
                        stream.zalloc = Z_NULL;
                        stream.zfree = Z_NULL;
                        stream.avail_in = (uint)data.length;
                        stream.next_in = (Bytef *)data.bytes;
                        stream.total_out = 0;
                        stream.avail_out = 0;
                        
                        NSMutableData *output = nil;
                        if (inflateInit2(&stream, 47) == Z_OK)
                        {
                            int status = Z_OK;
                            output = [NSMutableData dataWithCapacity:data.length * 2];
                            while (status == Z_OK)
                            {
                                if (stream.total_out >= output.length)
                                {
                                    output.length += data.length / 2;
                                }
                                stream.next_out = (uint8_t *)output.mutableBytes + stream.total_out;
                                stream.avail_out = (uInt)(output.length - stream.total_out);
                                status = inflate (&stream, Z_SYNC_FLUSH);
                            }
                            if (inflateEnd(&stream) == Z_OK)
                            {
                                if (status == Z_STREAM_END)
                                {
                                    output.length = stream.total_out;
                                }
                            }
                        }
                        
                        [output writeToFile:[finalPath stringByDeletingPathExtension] atomically:false];

                        NSError *removeError;
                        [[NSFileManager defaultManager] removeItemAtPath:finalPath error:&removeError];
                        if (removeError != NULL) {
                            NSLog(@"[Hyena] Unable to remove .gz, %@", removeError.localizedDescription);
                        }
                        
                        [self addFile:[finalPath stringByDeletingPathExtension] toArray:@"packages"];
                        [self->downloadDelegate predator:self finishedDownloadForFile:[self baseFileNameFromFullPath:finalPath] withError:NULL];
                    }
                }];
            }
        }
        else if ([[filename lastPathComponent] containsString:@".bz2"]) {
            if (responseCode == 304) {
                [downloadDelegate postStatusUpdate:[NSString stringWithFormat:@"%@ hasn't been modified", [url host]] atLevel:ZBLogLevelDescript];
            }
            else {
                NSString *listsPath = [ZBAppDelegate listsLocation];
                NSString *schemeless = [[[url URLByDeletingLastPathComponent] absoluteString] stringByReplacingOccurrencesOfString:[url scheme] withString:@""];
                NSString *safe = [[schemeless substringFromIndex:3] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                NSString *saveName = [NSString stringWithFormat:[[url absoluteString] rangeOfString:@"dists"].location == NSNotFound ? @"%@._%@" : @"%@%@", safe, filename];
                NSString *finalPath = [listsPath stringByAppendingPathComponent:saveName];
                
                [self moveFileFromLocation:location to:finalPath completion:^(BOOL success, NSError *error) {
                    if (!success && error != NULL) {
                        NSLog(@"[Zebra] Error while moving file at %@ to %@: %@", location, finalPath, error.localizedDescription);
                        [self->downloadDelegate predator:self finishedDownloadForFile:[self baseFileNameFromFullPath:finalPath] withError:error];
                    }
                    else {                        
                        FILE *f = fopen([finalPath UTF8String], "r");
                        FILE *output = fopen([[finalPath stringByDeletingPathExtension] UTF8String], "w");
                        
                        int bzError;
                        BZFILE *bzf;
                        char buf[4096];
                        
                        bzf = BZ2_bzReadOpen(&bzError, f, 0, 0, NULL, 0);
                        if (bzError != BZ_OK) {
                            fprintf(stderr, "[Hyena] E: BZ2_bzReadOpen: %d\n", bzError);
                        }
                        
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
                            [self moveFileFromLocation:[NSURL URLWithString:[@"file://" stringByAppendingString:finalPath]] to:[finalPath stringByDeletingPathExtension] completion:^(BOOL success, NSError *error) {
                                NSLog(@"Moved");
                            }];
                        }
                        
                        BZ2_bzReadClose(&bzError, bzf);
                        fclose(f);
                        fclose(output);
                        
                        NSError *removeError;
                        [[NSFileManager defaultManager] removeItemAtPath:finalPath error:&removeError];
                        if (removeError != NULL) {
                            NSLog(@"[Hyena] Unable to remove .bz2, %@", removeError.localizedDescription);
                        }
                        
                        [self addFile:[finalPath stringByDeletingPathExtension] toArray:@"packages"];
                        [self->downloadDelegate predator:self finishedDownloadForFile:[self baseFileNameFromFullPath:finalPath] withError:NULL];
                    }
                }];
            }
        }
        else if ([[filename lastPathComponent] containsString:@"Release"]) {
            if (responseCode == 304) {
                [downloadDelegate postStatusUpdate:[NSString stringWithFormat:@"%@ hasn't been modified", [url host]] atLevel:ZBLogLevelDescript];
            }
            else {
                NSString *listsPath = [ZBAppDelegate listsLocation];
                NSString *schemeless = [[[url URLByDeletingLastPathComponent] absoluteString] stringByReplacingOccurrencesOfString:[url scheme] withString:@""];
                NSString *safe = [[schemeless substringFromIndex:3] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                NSString *saveName = [NSString stringWithFormat:[[url absoluteString] rangeOfString:@"dists"].location == NSNotFound ? @"%@._%@" : @"%@%@", safe, filename];
                NSString *finalPath = [listsPath stringByAppendingPathComponent:saveName];
                
                [self moveFileFromLocation:location to:finalPath completion:^(BOOL success, NSError *error) {
                    if (!success && error != NULL) {
                        NSLog(@"[Zebra] Error while moving file at %@ to %@: %@", location, finalPath, error.localizedDescription);
                    }
                    else {
                        [self addFile:finalPath toArray:@"release"];
                    }
                }];
            }
        }
    }
}

- (NSString *)baseFileNameFromFullPath:(NSString *)path {
    if ([[path lastPathComponent] containsString:@"Packages"]) {
        return [[path lastPathComponent] stringByReplacingOccurrencesOfString:@"_Packages.bz2" withString:@""];
    }
    else {
        return [[path lastPathComponent] stringByReplacingOccurrencesOfString:@"_Release" withString:@""];
    }
}

/*
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSLog(@"%lld / %lld", totalBytesWritten, totalBytesExpectedToWrite);
    [downloadDelegate predator:self progressUpdate:(double)(totalBytesWritten / totalBytesExpectedToWrite) forPackage:[[ZBPackage alloc] init]];
}
*/

- (void)moveFileFromLocation:(NSURL *)location to:(NSString *)finalPath completion:(void (^)(BOOL success, NSError *error))completion {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL movedFileSuccess;
    NSError *fileManagerError;
    if ([fileManager fileExistsAtPath:finalPath]) {
        movedFileSuccess = [fileManager removeItemAtPath:finalPath error:&fileManagerError];
        
        if (!movedFileSuccess) {
            completion(movedFileSuccess, fileManagerError);
            return;
        }
    }
    
    movedFileSuccess = [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:finalPath] error:&fileManagerError];
    
    completion(movedFileSuccess, fileManagerError);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error != NULL)
        [self->downloadDelegate predator:self finishedDownloadForFile:[[[task originalRequest] URL] absoluteString] withError:error];
    tasks--;
    if (tasks == 0) {
        [downloadDelegate predator:self finishedAllDownloads:filenames];
    }
}

- (void)addFile:(NSString *)filename toArray:(NSString *)array {
    NSMutableArray *arr = [[filenames objectForKey:array] mutableCopy];
    if (arr == NULL) {
        arr = [NSMutableArray new];
    }
    
    [arr addObject:filename];
    [filenames setValue:arr forKey:array];
}

- (void)cancelAllTasksForSession:(NSURLSession *)session {
    [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if (!dataTasks || !dataTasks.count) {
            return;
        }
        for (NSURLSessionTask *task in dataTasks) {
            [task cancel];
        }
    }];
}

- (BOOL)isSessionOutOfTasks:(NSURLSession *)sesh {
    __block BOOL outOfTasks;
    [sesh getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        outOfTasks = dataTasks.count == 0;
    }];
    
    return outOfTasks;
}

@end
