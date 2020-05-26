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
#import <Sources/Helpers/ZBSourceManager.h>
#import <ZBAppDelegate.h>

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

@synthesize verificationStatus;
@synthesize label;

+ (ZBBaseSource *)zebraSource {
    return [[ZBBaseSource alloc] initWithArchiveType:@"deb" repositoryURI:@"https://getzbra.com/repo/" distribution:@"./" components:NULL];
}

+ (NSSet <ZBBaseSource *> *)baseSourcesFromURLs:(NSArray *)URLs {
    NSMutableSet *baseSources = [NSMutableSet new];
    
    for (NSURL *URL in URLs) {
        ZBBaseSource *source = [[ZBBaseSource alloc] initFromURL:URL];
        
        if (source) {
            [baseSources addObject:source];
        }
    }
    
    return baseSources;
}

+ (NSSet <ZBBaseSource *> *)baseSourcesFromList:(NSURL *)listLocation error:(NSError **)error {
    NSError *readError = NULL;
    NSString *sourceListContents = [NSString stringWithContentsOfURL:listLocation encoding:NSUTF8StringEncoding error:&readError];
    if (readError) {
        NSLog(@"[Zebra] Could not read sources list contents located at %@ reason: %@", [listLocation absoluteString], readError.localizedDescription);
        *error = readError;
        return NULL;
    }
    
    NSMutableSet *baseSources = [NSMutableSet new];
    if ([[listLocation pathExtension] isEqualToString:@"list"]) { //Debian source format
        NSArray *debLines = [sourceListContents componentsSeparatedByString:@"\n"];
        
        for (NSString *sourceLine in debLines) {
            if (![sourceLine isEqualToString:@""]) {
                if ([sourceLine characterAtIndex:0] == '#') continue;
                
                ZBBaseSource *source = [[ZBBaseSource alloc] initFromSourceLine:sourceLine];
                if (source) {
                    [baseSources addObject:source];
                }
            }
        }
    }
    else if ([[listLocation pathExtension] isEqualToString:@"sources"]) { //Sileo source format
        NSArray *sourceGroups = [sourceListContents componentsSeparatedByString:@"\n\n"];
        
        for (NSString *sourceGroup in sourceGroups) {
            if (![sourceGroup isEqualToString:@""]) {
                if ([sourceGroup characterAtIndex:0] == '#') continue;
                
                ZBBaseSource *source = [[ZBBaseSource alloc] initFromSourceGroup:sourceGroup];
                if (source) {
                    [baseSources addObject:source];
                }
            }
        }
    }

    return baseSources;
}

- (id)initWithArchiveType:(NSString *)archiveType repositoryURI:(NSString *)repositoryURI distribution:(NSString *)distribution components:(NSArray <NSString *> *_Nullable)components {
    
    // Making sure our parameters are correct
    if (!archiveType || !repositoryURI || !distribution) return NULL;
    if (![repositoryURI hasSuffix:@"/"]) {
        repositoryURI = [repositoryURI stringByAppendingString:@"/"];
    }
    
    self = [super init];
    
    if (self) {
        self->verificationStatus = ZBSourceUnverified;
        
        self->archiveType = archiveType;
        self->repositoryURI = repositoryURI;
        self->label = repositoryURI;
        self->distribution = distribution;
        if (components && [components count]) {
            NSMutableArray *check = [components mutableCopy];
            [check removeObject:@""];
            
            if ([check count]) {
                self->components = components;
            }
        }
        
        if ([self->distribution hasSuffix:@"/"]) { // If the distribution has a '/' at the end of it, it is likely a flat format
            if ([self->components count]) return NULL; // If you have components and a / at the end of your distribution, your source is malformed
            
            NSURL *baseURL = [NSURL URLWithString:self->repositoryURI];
            mainDirectoryURL = [NSURL URLWithString:self->distribution relativeToURL:baseURL];
            
            packagesDirectoryURL = mainDirectoryURL;
        }
        else if (self->components && [self->components count]) { // This repository has a non-flat format with a distribution and components
            NSString *mainDirectory = [NSString stringWithFormat:@"%@dists/%@/", self->repositoryURI, self->distribution];
            mainDirectoryURL = [NSURL URLWithString:mainDirectory];

            packagesDirectoryURL = [mainDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@/binary-%@/", self->components[0], [ZBDevice debianArchitecture]]];
        }
        
        if (!mainDirectoryURL) return NULL; // If somehow the mainDirectoryURL is malformed (either it didn't get created or the NSURL initializer returned NULL), the source cannot be used
        releaseURL = [mainDirectoryURL URLByAppendingPathComponent:@"Release"];
        
        NSString *mainDirectoryString = [mainDirectoryURL absoluteString];
        NSString *schemeless = [mainDirectoryURL scheme] ? [[mainDirectoryString stringByReplacingOccurrencesOfString:[mainDirectoryURL scheme] withString:@""] substringFromIndex:3] : mainDirectoryString; //Removes scheme and ://
        self->baseFilename = [schemeless stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    }
    
    return self;
}

- (id)initFromSourceLine:(NSString *)debLine {
    if (!debLine) return NULL;
    
    if ([debLine characterAtIndex:0] == '#') return NULL;
    debLine = [debLine stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableArray *lineComponents = [[debLine componentsSeparatedByString:@" "] mutableCopy];
    [lineComponents removeObject:@""]; //Remove empty strings from the line which exist for some reason
    
    NSUInteger count = [lineComponents count];
    NSString *archiveType = NULL;
    NSString *repositoryURI = NULL;
    NSString *distribution = NULL;
    NSMutableArray *sourceComponents = [NSMutableArray new];
    
    if (count > 0) {
        archiveType = lineComponents[0];
        if (count > 1) {
            repositoryURI = lineComponents[1];
            
            if (([self hasCFVersionComponent:repositoryURI]) && count == 3) { // Sources that are known to use CF number in URL but for some reason aren't written in the sources.list properly
                if ([repositoryURI containsString:@"apt.procurs.us"]) { // Have to treat this differently because its special
                    int roundedCF = 100.0 * floor((kCFCoreFoundationVersionNumber/100.0)+0.5);
                    if (roundedCF > kCFCoreFoundationVersionNumber) roundedCF -= 100.0;
                    distribution = [NSString stringWithFormat:@"iphoneos-arm64/%d", roundedCF];
                }
                else {
                    distribution = [NSString stringWithFormat:@"ios/%.2f", kCFCoreFoundationVersionNumber];
                }
                [sourceComponents addObject:@"main"];
            }
            else if (count > 2) {
                distribution = lineComponents[2];
                
                //Group all of the components into the components array
                for (int i = 3; i < count; i++) {
                    NSString *component = lineComponents[i];
                    if (component)  {
                        [sourceComponents addObject:component];
                    }
                }
            }
        }
        
        ZBBaseSource *baseSource = [self initWithArchiveType:archiveType repositoryURI:repositoryURI distribution:distribution components:(NSArray *)sourceComponents];
        
        return baseSource;
    }
    
    return [super init];
}

- (id)initFromSourceGroup:(NSString *)sourceGroup {
    if (!sourceGroup) return NULL;
    
    NSMutableDictionary *source = [NSMutableDictionary new];
    [sourceGroup enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        if (![line hasPrefix:@"#"]) {
            NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
            if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
            if (pair.count != 2) return;
            NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            source[key] = value;
        }
    }];
    
    if ([source count] >= 3) {
        if (![source objectForKey:@"Types"] || ![source objectForKey:@"URIs"] || ![source objectForKey:@"Suites"]) return NULL;
        
        NSString *archiveType = source[@"Types"];
        NSString *repositoryURI = source[@"URIs"];
        NSString *distribution = source[@"Suites"];
        
        NSString *components = source[@"Components"] ?: @"";
        NSArray *sourceComponents = [components componentsSeparatedByString:@" "];
        
        ZBBaseSource *baseSource = [self initWithArchiveType:archiveType repositoryURI:repositoryURI distribution:distribution components:sourceComponents];
        
        return baseSource;
    }
    
    return [super init];
}

- (id)initFromURL:(NSURL *)url {
    return [self initFromSourceLine:[ZBSourceManager debLineForURL:url]];
}

- (BOOL)hasCFVersionComponent:(NSString * _Nullable)repositoryURI_ {
    NSString *repositoryURI = repositoryURI_ ?: self.repositoryURI;
    return [repositoryURI containsString:@"apt.procurs.us"] || [repositoryURI containsString:@"apt.bingner.com"] || [repositoryURI containsString:@"apt.saurik.com"];
}

- (void)verify:(nullable void (^)(ZBSourceVerificationStatus status))completion {
    if (verificationStatus != ZBSourceUnverified && completion) {
        completion(verificationStatus);
        return;
    }
    
    completion(ZBSourceVerifying);
    
    __block int tasks = 5;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = [ZBDownloadManager headers];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSMutableURLRequest *xzRequest = [NSMutableURLRequest requestWithURL:[packagesDirectoryURL URLByAppendingPathComponent:@"Packages.xz"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [xzRequest setHTTPMethod:@"HEAD"];
    
    NSURLSessionDataTask *xzTask = [session dataTaskWithRequest:xzRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 && [self isNonBlacklistedMIMEType:httpResponse.MIMEType]) {
            [session invalidateAndCancel];
            
            self->verificationStatus = ZBSourceExists;
            if (completion) completion(self->verificationStatus);
        }
        else if (--tasks == 0) {
            self->verificationStatus = ZBSourceImaginary;
            if (completion) completion(self->verificationStatus);
        }
    }];
    [xzTask resume];
    
    NSMutableURLRequest *bz2Request = [NSMutableURLRequest requestWithURL:[packagesDirectoryURL URLByAppendingPathComponent:@"Packages.bz2"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [bz2Request setHTTPMethod:@"HEAD"];
    
    NSURLSessionDataTask *bz2Task = [session dataTaskWithRequest:bz2Request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 && [self isNonBlacklistedMIMEType:httpResponse.MIMEType]) {
            [session invalidateAndCancel];
            
            self->verificationStatus = ZBSourceExists;
            if (completion) completion(self->verificationStatus);
        }
        else if (--tasks == 0) {
            self->verificationStatus = ZBSourceImaginary;
            if (completion) completion(self->verificationStatus);
        }
    }];
    [bz2Task resume];
    
    NSMutableURLRequest *gzRequest = [NSMutableURLRequest requestWithURL:[packagesDirectoryURL URLByAppendingPathComponent:@"Packages.gz"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [gzRequest setHTTPMethod:@"HEAD"];
    
    NSURLSessionDataTask *gzTask = [session dataTaskWithRequest:gzRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 && [self isNonBlacklistedMIMEType:httpResponse.MIMEType]) {
            [session invalidateAndCancel];
            
            self->verificationStatus = ZBSourceExists;
            if (completion) completion(self->verificationStatus);
        }
        else if (--tasks == 0) {
            self->verificationStatus = ZBSourceImaginary;
            if (completion) completion(self->verificationStatus);
        }
    }];
    [gzTask resume];
    
    NSMutableURLRequest *lzmaRequest = [NSMutableURLRequest requestWithURL:[packagesDirectoryURL URLByAppendingPathComponent:@"Packages.lzma"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [lzmaRequest setHTTPMethod:@"HEAD"];
    
    NSURLSessionDataTask *lzmaTask = [session dataTaskWithRequest:lzmaRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 && [self isNonBlacklistedMIMEType:httpResponse.MIMEType]) {
            [session invalidateAndCancel];
            
            self->verificationStatus = ZBSourceExists;
            if (completion) completion(self->verificationStatus);
        }
        else if (--tasks == 0) {
            self->verificationStatus = ZBSourceImaginary;
            if (completion) completion(self->verificationStatus);
        }
    }];
    [lzmaTask resume];
    
    NSMutableURLRequest *uncompressedRequest = [NSMutableURLRequest requestWithURL:[packagesDirectoryURL URLByAppendingPathComponent:@"Packages"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [uncompressedRequest setHTTPMethod:@"HEAD"];
    
    NSURLSessionDataTask *uncompressedTask = [session dataTaskWithRequest:uncompressedRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 && [self isNonBlacklistedMIMEType:httpResponse.MIMEType]) {
            [session invalidateAndCancel];
            
            self->verificationStatus = ZBSourceExists;
            if (completion) completion(self->verificationStatus);
        }
        else if (--tasks == 0) {
            self->verificationStatus = ZBSourceImaginary;
            if (completion) completion(self->verificationStatus);
        }
    }];
    [uncompressedTask resume];
}

- (BOOL)isNonBlacklistedMIMEType:(NSString *)mimeType {
    return mimeType == nil || [mimeType length] == 0 || (![mimeType hasPrefix:@"audio/"] && ![mimeType hasPrefix:@"font/"] && ![mimeType hasPrefix:@"image/"] && ![mimeType hasPrefix:@"video/"] && ![mimeType isEqualToString:@"text/html"] && ![mimeType isEqualToString:@"text/css"]);
}

- (void)getLabel:(void (^)(NSString *label))completion {
    if (![label isEqualToString:repositoryURI]) completion(label);
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = [ZBDownloadManager headers];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSMutableURLRequest *releaseRequest = [NSMutableURLRequest requestWithURL:releaseURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    
    NSURLSessionDataTask *releaseTask = [session dataTaskWithRequest:releaseRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *releaseFile = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        __block NSString *label = NULL;
        [releaseFile enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
            if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
            if (pair.count != 2) return;
            NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            if ([key isEqualToString:@"Origin"] || [key isEqualToString:@"Label"]) {
                NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                label = value;
                return;
            }
        }];
        
        if (label) {
            self->label = label;
            completion(label);
            return;
        }
        
        self->label = [self->repositoryURI copy];
        completion(label);
    }];
    [releaseTask resume];
}

- (NSString *)debLine {
    if (self.components && [components count]) {
        return [NSString stringWithFormat:@"%@ %@ %@ %@\n", self.archiveType, self.repositoryURI, self.distribution, [self.components componentsJoinedByString:@" "]];
    }
    
    return [NSString stringWithFormat:@"%@ %@ %@\n", self.archiveType, self.repositoryURI, self.distribution];
}

- (BOOL)canDelete {
    return YES;
}

- (BOOL)isEqual:(ZBBaseSource *)object {
    if (!object)
        return NO;
    
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[ZBBaseSource class]])
        return NO;
    
    if (!object.archiveType || !object.repositoryURI || !object.distribution)
        return NO;
    
    NSString *repositoryURISchemeless;
    if ([self.repositoryURI hasPrefix:@"http:"]) {
        repositoryURISchemeless = [self.repositoryURI stringByReplacingOccurrencesOfString:@"http:" withString:@""];
    }
    else if ([self.repositoryURI hasPrefix:@"https:"]) {
        repositoryURISchemeless = [self.repositoryURI stringByReplacingOccurrencesOfString:@"https:" withString:@""];
    }
    
    BOOL archiveTypeEqual = [[object archiveType] isEqualToString:[self archiveType]];
    BOOL repositoryURIEqual = [[object repositoryURI] hasSuffix:repositoryURISchemeless ?: self.repositoryURI];
    BOOL distributionEqual = [[object distribution] isEqualToString:[self distribution]];
    
    BOOL componentsEqual = NO;
    if ([object components] == NULL && [self components] == NULL) componentsEqual = YES;
    else if ([[object components] isEqual:[self components]]) componentsEqual = YES;
    
    return (archiveTypeEqual && repositoryURIEqual && distributionEqual && componentsEqual);
}

- (NSUInteger)hash {
    NSUInteger repositoryURIHash = 0;
    if ([self.repositoryURI hasPrefix:@"http:"]) {
        repositoryURIHash = [[self.repositoryURI stringByReplacingOccurrencesOfString:@"http:" withString:@""] hash];
    }
    else if ([self.repositoryURI hasPrefix:@"https:"]) {
        repositoryURIHash = [[self.repositoryURI stringByReplacingOccurrencesOfString:@"https:" withString:@""] hash];
    }
    
    return [self.archiveType hash] + repositoryURIHash + [self.distribution hash] + [self.components hash];
}

- (BOOL)exists {
    NSSet *sources = [[self class] baseSourcesFromList:[ZBAppDelegate sourcesListURL] error:nil];
    return [sources containsObject:self];
}

@end
