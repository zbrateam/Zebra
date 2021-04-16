//
//  ZBDummySource.m
//  Zebra
//
//  Created by Wilson Styres on 4/15/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBDummySource.h"

#import <ZBDevice.h>

@implementation ZBDummySource

- (id)initWithArchiveType:(NSString *)archiveType repositoryURI:(NSString *)repositoryURI distribution:(NSString *)distribution components:(NSArray <NSString *> *_Nullable)components {
    
    // Making sure our parameters are correct
    if (!archiveType || !repositoryURI || !distribution) return NULL;
    if (![repositoryURI hasSuffix:@"/"]) {
        repositoryURI = [repositoryURI stringByAppendingString:@"/"];
    }
    
    self = [super init];
    
    if (self) {
        self.verificationStatus = ZBSourceUnverified;
        
        _archiveType = archiveType;
        _repositoryURI = repositoryURI;
        _origin = repositoryURI;
        _distribution = distribution;
        
        if (components && [components count]) {
            NSMutableArray *check = [components mutableCopy];
            [check removeObject:@""];
            
            if ([check count]) {
                _components = components;
            }
        }
        
        if ([_distribution hasSuffix:@"/"]) { // If the distribution has a '/' at the end of it, it is likely a flat format
            if ([_components count]) return NULL; // If you have components and a / at the end of your distribution, your source is malformed
            
            NSURL *baseURL = [NSURL URLWithString:_repositoryURI];
            mainDirectoryURL = [NSURL URLWithString:_distribution relativeToURL:baseURL];
            
            packagesDirectoryURL = mainDirectoryURL;
        }
        else if (_components && _components.count) { // This repository has a non-flat format with a distribution and components
            NSString *mainDirectory = [NSString stringWithFormat:@"%@dists/%@/", _repositoryURI, _distribution];
            mainDirectoryURL = [NSURL URLWithString:mainDirectory];

            packagesDirectoryURL = [mainDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@/binary-%@/", _components[0], [ZBDevice debianArchitecture]]];
        }
        
        if (!mainDirectoryURL) return NULL; // If somehow the mainDirectoryURL is malformed (either it didn't get created or the NSURL initializer returned NULL), the source cannot be used
        releaseURL = [mainDirectoryURL URLByAppendingPathComponent:@"Release"];
        
#if TARGET_OS_MACCATALYST
        _iconURL = [mainDirectoryURL URLByAppendingPathComponent:@"RepoIcon.png"];
#else
        _iconURL = [mainDirectoryURL URLByAppendingPathComponent:@"CydiaIcon.png"];
#endif
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
        
        ZBDummySource *dummySource = [self initWithArchiveType:archiveType repositoryURI:repositoryURI distribution:distribution components:(NSArray *)sourceComponents];
        
        return dummySource;
    }
    
    return NULL;
}

- (id)initWithURL:(NSURL *)URL {
    if (!URL) return NULL;
    
    NSDictionary *knownDistSources = @{
        @"apt.thebigboss.org": @"deb http://apt.thebigboss.org/repofiles/cydia/ stable main",
        @"apt.modmyi.com": @"deb http://apt.modmyi.com/ stable main",
        @"apt.saurik.com": [NSString stringWithFormat:@"deb http://apt.saurik.com/ ios/%.2f main", kCFCoreFoundationVersionNumber],
        @"apt.bingner.com": [NSString stringWithFormat:@"deb https://apt.bingner.com/ ios/%.2f main", kCFCoreFoundationVersionNumber],
        @"cydia.zodttd.com": @"deb http://cydia.zodttd.com/repo/cydia/ stable main"
    };
    
    NSString *debLine = knownDistSources[[URL host]] ?: [NSString stringWithFormat:@"deb %@ ./", [URL absoluteString]];
    return [self initFromSourceLine:debLine];
}

- (BOOL)hasCFVersionComponent:(NSString * _Nullable)repositoryURI_ {
    NSString *repositoryURI = repositoryURI_ ?: self.repositoryURI;
    return [repositoryURI containsString:@"apt.procurs.us"] || [repositoryURI containsString:@"apt.bingner.com"] || [repositoryURI containsString:@"apt.saurik.com"];
}


@end
