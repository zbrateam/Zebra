//
//  ZBSource.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBSource.h"
#import "ZBSourceManager.h"
#import "UICKeyChainStore.h"
#import <ZBAppDelegate.h>
#import <Database/ZBDatabaseManager.h>
#import <Database/ZBColumn.h>

@implementation ZBSource

@synthesize sourceDescription;
@synthesize origin;
@synthesize version;
@synthesize suite;
@synthesize codename;
@synthesize architectures;
@synthesize repoID;
@synthesize supportSileoPay;

const char *textColumn(sqlite3_stmt *statement, int column) {
    return (const char *)sqlite3_column_text(statement, column);
}

+ (ZBSource *)repoMatchingRepoID:(int)repoID {
    return [[ZBSourceManager sharedInstance] repos][@(repoID)];
}

+ (ZBSource *)localRepo:(int)repoID {
    ZBSource *local = [[ZBSource alloc] init];
    [local setOrigin:NSLocalizedString(@"Local Repository", @"")];
    [local setSourceDescription:NSLocalizedString(@"Locally installed packages", @"")];
    [local setRepoID:repoID];
    [local setBaseFilename:@"/var/lib/dpkg/status"];
    return local;
}

+ (ZBSource *)repoFromBaseURL:(NSString *)baseURL {
    return [[ZBDatabaseManager sharedInstance] repoFromBaseURL:baseURL];
}

+ (BOOL)exists:(NSString *)urlString {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    NSRange dividerRange = [urlString rangeOfString:@"://"];
    NSUInteger divide = NSMaxRange(dividerRange);
    NSString *baseURL = divide > [urlString length] ? urlString : [urlString substringFromIndex:divide];
    
    return [databaseManager repoIDFromBaseURL:baseURL strict:false] > 0;
}

- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement {
    const char *archiveTypeChars   = textColumn(statement, ZBSourceColumnArchiveType);
    const char *repositoryURIChars = textColumn(statement, ZBSourceColumnRepositoryURI);
    const char *distributionChars  = textColumn(statement, ZBSourceColumnDistribution);
    const char *componenetsChars   = textColumn(statement, ZBSourceColumnComponents);
    
    NSArray *components;
    if (componenetsChars != 0 && strcmp(componenetsChars, "") != 0) {
        components = [[NSString stringWithUTF8String:componenetsChars] componentsSeparatedByString:@" "];
    }
    
    self = [super initWithArchiveType:[NSString stringWithUTF8String:archiveTypeChars] repositoryURI:[NSString stringWithUTF8String:repositoryURIChars] distribution:[NSString stringWithUTF8String:distributionChars] components:components];
    
    if (self) {
        const char *descriptionChars   = textColumn(statement, ZBSourceColumnDescription);
        const char *originChars        = textColumn(statement, ZBSourceColumnOrigin);
        const char *labelChars         = textColumn(statement, ZBSourceColumnLabel);
        const char *versionChars       = textColumn(statement, ZBSourceColumnVersion);
        const char *suiteChars         = textColumn(statement, ZBSourceColumnSuite);
        const char *codenameChars      = textColumn(statement, ZBSourceColumnCodename);
        const char *architectureChars  = textColumn(statement, ZBSourceColumnArchitectures);
        const char *baseFilenameChars  = textColumn(statement, ZBSourceColumnBaseFilename);

        [self setSourceDescription:descriptionChars != 0 ? [[NSString alloc] initWithUTF8String:descriptionChars] : NULL];
        [self setOrigin:originChars != 0 ? [[NSString alloc] initWithUTF8String:originChars] : NSLocalizedString(@"Unknown", @"")];
        [self setLabel:labelChars != 0 ? [[NSString alloc] initWithUTF8String:labelChars] : NSLocalizedString(@"Unknown", @"")];
        [self setVersion:versionChars != 0 ? [[NSString alloc] initWithUTF8String:versionChars] : NSLocalizedString(@"Unknown", @"")];
        [self setSuite:suiteChars != 0 ? [[NSString alloc] initWithUTF8String:suiteChars] : NSLocalizedString(@"Unknown", @"")];
        [self setCodename:codenameChars != 0 ? [[NSString alloc] initWithUTF8String:codenameChars] : NSLocalizedString(@"Unknown", @"")];
        
        if (architectureChars != 0) {
            NSArray *architectures = [[NSString stringWithUTF8String:architectureChars] componentsSeparatedByString:@" "];
            [self setArchitectures:architectures];
        }
        else {
            [self setArchitectures:@[@"all"]];
        }
        
        [self setBaseFilename:baseFilenameChars != 0 ? [[NSString alloc] initWithUTF8String:baseFilenameChars] : NULL];
        [self setRepoID:sqlite3_column_int(statement, ZBSourceColumnRepoID)];
        
        [self setIconURL:[self.mainDirectoryURL URLByAppendingPathComponent:@"CydiaIcon.png"]];

        //rewrite eventually
        if ([self.repositoryURI containsString:@"https"]) {
            NSString *requestURL;
            if ([self.repositoryURI hasSuffix:@"/"]) {
                requestURL = [NSString stringWithFormat:@"%@payment_endpoint", self.repositoryURI];
            } else {
                requestURL = [NSString stringWithFormat:@"/%@/payment_endpoint", self.repositoryURI];
            }
            NSURL *url = [NSURL URLWithString:requestURL];
            NSURLSession *session = [NSURLSession sharedSession];
            [[session dataTaskWithURL:url
                    completionHandler:^(NSData *data,
                                        NSURLResponse *response,
                                        NSError *error) {
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                        NSString *endpoint = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        if ([endpoint length] != 0 && (long)[httpResponse statusCode] == 200) {
                            UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
                            keychain[self.repositoryURI] = endpoint;
                            [self setSupportSileoPay:YES];
                        }
                    }] resume];
        }
        // prevent constant network spam
        if (!self.checkedSupportFeaturedPackages) {
            // Check for featured string
            NSString *requestURL;
            if ([self.repositoryURI hasSuffix:@"/"]) {
                requestURL = [NSString stringWithFormat:@"%@sileo-featured.json", self.repositoryURI];
            } else {
                requestURL = [NSString stringWithFormat:@"/%@/sileo-featured.json", self.repositoryURI];
            }
            NSURL *checkingURL = [NSURL URLWithString:requestURL];
            NSURLSession *session = [NSURLSession sharedSession];
            [[session dataTaskWithURL:checkingURL
                    completionHandler:^(NSData *data,
                                        NSURLResponse *response,
                                        NSError *error) {
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                        if (data != nil && (long)[httpResponse statusCode] != 404) {
                            [self setSupportsFeaturedPackages:YES];
                        }
                    }] resume];
            [self setCheckedSupportFeaturedPackages:YES];
        }
    }
    
    return self;
}

- (BOOL)canDelete {
    return ![[self baseFilename] isEqualToString:@"getzbra.com_repo_._"];
}

- (BOOL)isEqual:(ZBSource *)object {
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[ZBSource class]])
        return NO;
    
    return [[object baseFilename] isEqual:[self baseFilename]];
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ %@ %d", self.label, self.repositoryURI, self.repoID];
}

@end
