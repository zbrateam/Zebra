//
//  ZBBaseSource.m
//  Zebra
//
//  Created by Wilson Styres on 1/2/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBBaseSource.h"

#import <ZBDevice.h>
#import <Downloads/ZBDownloadManager.h>

@implementation ZBBaseSource

@synthesize archiveType;
@synthesize repositoryURI;
@synthesize distribution;
@synthesize components;

@synthesize mainDirectoryURL;
@synthesize packagesDirectoryURL;
@synthesize releaseURL;

@synthesize releaseTaskIdentifier;
@synthesize packagesTaskIdentifier;

@synthesize packagesTaskCompleted;
@synthesize releaseTaskCompleted;

@synthesize packagesFilePath;
@synthesize releaseFilePath;

@synthesize baseFilename;

@synthesize verifying;
@synthesize verified;
@synthesize hasBeenVerified;

+ (ZBBaseSource *)zebraSource {
    return [[ZBBaseSource alloc] initWithArchiveType:@"deb" repositoryURI:@"https://getzbra.com/repo/" distribution:@"./" components:NULL];
}

+ (NSSet <ZBBaseSource *> *)baseSourcesFromList:(NSURL *)listLocation error:(NSError **)error {
    NSError *readError;
    NSString *sourceListContents = [NSString stringWithContentsOfURL:listLocation encoding:NSUTF8StringEncoding error:&readError];
    if (readError) {
        NSLog(@"[Zebra] Could not read sources list contents located at %@ reason: %@", [listLocation absoluteString], readError.localizedDescription);
        *error = readError;
        return NULL;
    }
    
    NSMutableSet *baseRepos = [NSMutableSet new];
    if ([[listLocation pathExtension] isEqualToString:@"list"]) { //Debian source format
        NSArray *debLines = [sourceListContents componentsSeparatedByString:@"\n"];
        
        for (NSString *sourceLine in debLines) {
            if (![sourceLine isEqualToString:@""]) {
                if ([sourceLine characterAtIndex:0] == '#') continue;
                
                ZBBaseSource *repo = [[ZBBaseSource alloc] initFromSourceLine:sourceLine];
                if (repo) {
                    [baseRepos addObject:repo];
                }
            }
        }
    }
    else if ([[listLocation pathExtension] isEqualToString:@"sources"]) { //Sileo source format
        NSArray *sourceGroups = [sourceListContents componentsSeparatedByString:@"\n\n"];
        
        for (NSString *sourceGroup in sourceGroups) {
            if (![sourceGroup isEqualToString:@""]) {
                if ([sourceGroup characterAtIndex:0] == '#') continue;
                
                ZBBaseSource *repo = [[ZBBaseSource alloc] initFromSourceGroup:sourceGroup];
                if (repo) {
                    [baseRepos addObject:repo];
                }
            }
        }
    }

    return baseRepos;
}

- (id)initWithArchiveType:(NSString *)archiveType repositoryURI:(NSString *)repositoryURI distribution:(NSString *)distribution components:(NSArray <NSString *> *_Nullable)components {
    self = [super init];
    
    if (self) {
        self->verifying = NO;
        self->verified = NO;
        
        self->archiveType = archiveType;
        self->repositoryURI = repositoryURI;
        self->distribution = distribution;
        if (components && [components count]) {
            self->components = components;
        }
        
        if (![distribution isEqualToString:@"./"]) { //Set packages and release URLs to follow dist format
            NSString *mainDirectory = [NSString stringWithFormat:@"%@dists/%@/", repositoryURI, distribution];
            mainDirectoryURL = [NSURL URLWithString:mainDirectory];

            packagesDirectoryURL = [mainDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@/binary-%@/", components[0], [ZBDevice debianArchitecture]]];
            releaseURL = [mainDirectoryURL URLByAppendingPathComponent:@"Release"];
        }
        else {
            mainDirectoryURL = [NSURL URLWithString:repositoryURI];
            mainDirectoryURL = [mainDirectoryURL URLByAppendingPathComponent:@"./"];
            
            packagesDirectoryURL = mainDirectoryURL;
            releaseURL = [mainDirectoryURL URLByAppendingPathComponent:@"Release"];
        }
        
        NSString *schemeless = [[[mainDirectoryURL absoluteString] stringByReplacingOccurrencesOfString:[mainDirectoryURL scheme] withString:@""] substringFromIndex:3]; //Removes scheme and ://
        self->baseFilename = [schemeless stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    }
    
    return self;
}

- (id)initFromSourceLine:(NSString *)debLine {
    if ([debLine characterAtIndex:0] == '#') return NULL;
    debLine = [debLine stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    debLine = [debLine stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    NSMutableArray *lineComponents = [[debLine componentsSeparatedByString:@" "] mutableCopy];
    [lineComponents removeObject:@""]; //Remove empty strings from the line which exist for some reason
    
    if ([lineComponents count] >= 3) {
        NSString *archiveType = lineComponents[0];
        NSString *repositoryURI = lineComponents[1];
        NSString *distribution = lineComponents[2];
        
        //Group all of the components into the components array
        NSMutableArray *sourceComponents = [NSMutableArray new];
        for (int i = 3; i < [lineComponents count]; i++) {
            NSString *component = lineComponents[i];
            if (component)  {
                [sourceComponents addObject:component];
            }
        }
        
        ZBBaseSource *baseSource = [self initWithArchiveType:archiveType repositoryURI:repositoryURI distribution:distribution components:(NSArray *)sourceComponents];
        
        return baseSource;
    }
    
    return [super init];
}

- (id)initFromSourceGroup:(NSString *)sourceGroup {
    if ([sourceGroup characterAtIndex:0] == '#') return NULL;
    
    NSMutableDictionary *source = [NSMutableDictionary new];
    [sourceGroup enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
        if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
        if (pair.count != 2) return;
        NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        source[key] = value;
    }];
    
    if ([source count] >= 3) {
        NSString *archiveType = source[@"Types"];
        NSString *repositoryURI = source[@"URIs"];
        NSString *distribution = source[@"Suites"];
        
        NSString *components = source[@"Components"];
        NSArray *sourceComponents = [components componentsSeparatedByString:@" "];
        
        ZBBaseSource *baseSource = [self initWithArchiveType:archiveType repositoryURI:repositoryURI distribution:distribution components:sourceComponents];
        
        return baseSource;
    }
    
    return [super init];
}

- (void)verify:(nullable void (^)(BOOL exists))completion {
    if (hasBeenVerified) {
        completion(verified);
    }
    
    __block int tasks = 5;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = [ZBDownloadManager headers];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSMutableURLRequest *xzRequest = [NSMutableURLRequest requestWithURL:[packagesDirectoryURL URLByAppendingPathComponent:@"Packages.xz"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [xzRequest setHTTPMethod:@"HEAD"];
    
    NSURLSessionDataTask *xzTask = [session dataTaskWithRequest:xzRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            [session invalidateAndCancel];
            
            self->hasBeenVerified = YES;
            self->verifying = NO;
            self->verified = YES;
            if (completion) completion(YES);
        }
        else if (--tasks == 0) {
            self->hasBeenVerified = YES;
            self->verifying = NO;
            self->verified = NO;
            if (completion) completion(NO);
        }
    }];
    [xzTask resume];
    
    NSMutableURLRequest *bz2Request = [NSMutableURLRequest requestWithURL:[packagesDirectoryURL URLByAppendingPathComponent:@"Packages.bz2"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [bz2Request setHTTPMethod:@"HEAD"];
    
    NSURLSessionDataTask *bz2Task = [session dataTaskWithRequest:bz2Request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            [session invalidateAndCancel];
            
            self->hasBeenVerified = YES;
            self->verifying = NO;
            self->verified = YES;
            if (completion) completion(YES);
        }
        else if (--tasks == 0) {
            self->hasBeenVerified = YES;
            self->verifying = NO;
            self->verified = NO;
            if (completion) completion(NO);
        }
    }];
    [bz2Task resume];
    
    NSMutableURLRequest *gzRequest = [NSMutableURLRequest requestWithURL:[packagesDirectoryURL URLByAppendingPathComponent:@"Packages.gz"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [gzRequest setHTTPMethod:@"HEAD"];
    
    NSURLSessionDataTask *gzTask = [session dataTaskWithRequest:gzRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            [session invalidateAndCancel];
            
            self->hasBeenVerified = YES;
            self->verifying = NO;
            self->verified = YES;
            if (completion) completion(YES);
        }
        else if (--tasks == 0) {
            self->hasBeenVerified = YES;
            self->verifying = NO;
            self->verified = NO;
            if (completion) completion(NO);
        }
    }];
    [gzTask resume];
    
    NSMutableURLRequest *lzmaRequest = [NSMutableURLRequest requestWithURL:[packagesDirectoryURL URLByAppendingPathComponent:@"Packages.lzma"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [lzmaRequest setHTTPMethod:@"HEAD"];
    
    NSURLSessionDataTask *lzmaTask = [session dataTaskWithRequest:lzmaRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            [session invalidateAndCancel];
            
            self->hasBeenVerified = YES;
            self->verifying = NO;
            self->verified = YES;
            if (completion) completion(YES);
        }
        else if (--tasks == 0) {
            self->hasBeenVerified = YES;
            self->verifying = NO;
            self->verified = NO;
            if (completion) completion(NO);
        }
    }];
    [lzmaTask resume];
    
    NSMutableURLRequest *uncompressedRequest = [NSMutableURLRequest requestWithURL:[packagesDirectoryURL URLByAppendingPathComponent:@"Packages"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [uncompressedRequest setHTTPMethod:@"HEAD"];
    
    NSURLSessionDataTask *uncompressedTask = [session dataTaskWithRequest:uncompressedRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            [session invalidateAndCancel];
            
            self->hasBeenVerified = YES;
            self->verifying = NO;
            self->verified = YES;
            if (completion) completion(YES);
        }
        else if (--tasks == 0) {
            self->hasBeenVerified = YES;
            self->verifying = NO;
            self->verified = NO;
            if (completion) completion(NO);
        }
    }];
    [uncompressedTask resume];
}

- (void)getLabel:(void (^)(NSString *label))completion {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = [ZBDownloadManager headers];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSMutableURLRequest *releaseRequest = [NSMutableURLRequest requestWithURL:releaseURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    
    NSURLSessionDataTask *releaseTask = [session dataTaskWithRequest:releaseRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *releaseFile = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [releaseFile enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
            if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
            if (pair.count != 2) return;
            NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            if ([key isEqualToString:@"Label"]) {
                NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                completion(value);
            }
        }];
    }];
    [releaseTask resume];
}

- (NSString *)label {
    return self.repositoryURI;
}

- (NSString *)debLine {
    if (self.components && [components count]) {
        return [NSString stringWithFormat:@"%@ %@ %@ %@\n", self.archiveType, self.repositoryURI, self.distribution, [self.components componentsJoinedByString:@" "]];
    }
    
    return [NSString stringWithFormat:@"%@ %@ %@\n", self.archiveType, self.repositoryURI, self.distribution];
}

- (BOOL)canDelete {
    return true;
}

- (BOOL)isEqual:(ZBBaseSource *)object {
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[ZBBaseSource class]])
        return NO;
    
    BOOL archiveTypeEqual = [[object archiveType] isEqualToString:[self archiveType]];
    BOOL repositoryURIEqual = [[object repositoryURI] isEqualToString:[self repositoryURI]];
    BOOL distributionEqual = [[object distribution] isEqualToString:[self distribution]];
    
    BOOL componentsEqual = NO;
    if ([object components] == NULL && [self components] == NULL) componentsEqual = YES;
    else if ([[object components] isEqual:[self components]]) componentsEqual = YES;
    
    return (archiveTypeEqual && repositoryURIEqual && distributionEqual && componentsEqual);
}

@end
