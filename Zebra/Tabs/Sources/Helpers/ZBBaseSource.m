//
//  ZBBaseSource.m
//  Zebra
//
//  Created by Wilson Styres on 1/2/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBBaseSource.h"

#import <ZBDevice.h>

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

+ (ZBBaseSource *)zebraSource {
    return [[ZBBaseSource alloc] initWithArchiveType:@"deb" repositoryURI:@"https://getzbra.com/repo/" distribution:@"./" components:NULL];
}

+ (NSArray <ZBBaseSource *> *)baseSourcesFromList:(NSString *)listPath error:(NSError **)error {
    NSError *readError;
    NSString *sourceListContents = [NSString stringWithContentsOfFile:listPath encoding:NSUTF8StringEncoding error:&readError];
    if (readError) {
        NSLog(@"[Zebra] Could not read sources list contents located at %@ reason: %@", listPath, readError.localizedDescription);
        *error = readError;
        return NULL;
    }
    
    NSArray *debLines = [sourceListContents componentsSeparatedByString:@"\n"];
    NSMutableArray *baseRepos = [NSMutableArray new];
    for (NSString *sourceLine in debLines) {
        if (![sourceLine isEqualToString:@""]) {
            if ([sourceLine characterAtIndex:0] == '#') continue;
            
            ZBBaseSource *repo = [[ZBBaseSource alloc] initFromSourceLine:sourceLine];
            if (repo) {
                [baseRepos addObject:repo];
            }
        }
    }

    ZBBaseSource *zebraSource = [self zebraSource];
    if (![baseRepos containsObject:zebraSource]) {
        [baseRepos addObject:zebraSource];
    }

    return baseRepos;
}

- (id)initWithArchiveType:(NSString *)archiveType repositoryURI:(NSString *)repositoryURI distribution:(NSString *)distribution components:(NSArray <NSString *> *_Nullable)components {
    self = [super init];
    
    if (self) {
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
    
    return ([[object archiveType] isEqualToString:[self archiveType]] &&
            [[object repositoryURI] isEqualToString:[self repositoryURI]] &&
            [[object distribution] isEqualToString:[self distribution]] &&
            [[object components] count] == [[self components] count]);
}

@end
