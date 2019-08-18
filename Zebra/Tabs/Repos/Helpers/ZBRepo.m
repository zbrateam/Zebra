//
//  ZBRepo.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBRepo.h"
#import "ZBRepoManager.h"
#import "UICKeyChainStore.h"
#import <ZBAppDelegate.h>
#import <Database/ZBDatabaseManager.h>
#import <Database/ZBColumn.h>

@implementation ZBRepo

@synthesize origin;
@synthesize desc;
@synthesize baseFileName;
@synthesize baseURL;
@synthesize secure;
@synthesize repoID;
@synthesize iconURL;
@synthesize defaultRepo;
@synthesize suite;
@synthesize components;
@synthesize shortURL;
@synthesize supportSileoPay;

+ (ZBRepo *)repoMatchingRepoID:(int)repoID {
    return [[ZBRepoManager sharedInstance] repos][@(repoID)];
}

+ (ZBRepo *)localRepo:(int)repoID {
    ZBRepo *local = [[ZBRepo alloc] init];
    [local setOrigin:@"Local Repository"];
    [local setDesc:@"Locally installed packages"];
    [local setRepoID:repoID];
    [local setBaseFileName:@"/var/lib/dpkg/status"];
    return local;
}

- (id)initWithOrigin:(NSString *)origin description:(NSString *)description baseFileName:(NSString *)bfn baseURL:(NSString *)baseURL secure:(BOOL)sec repoID:(int)repoIdentifier iconURL:(NSURL *)icoURL isDefault:(BOOL)isDefault suite:(NSString *)sweet components:(NSString *)comp shortURL:(NSString *)shortA {
    
    self = [super init];
    
    if (self) {
        [self setOrigin:origin];
        [self setDesc:description];
        [self setBaseFileName:bfn];
        [self setBaseURL:baseURL];
        [self setSecure:sec];
        [self setRepoID:repoIdentifier];
        [self setIconURL:icoURL];
        [self setDefaultRepo:isDefault];
        [self setSuite:sweet];
        [self setComponents:comp];
        [self setShortURL:shortA];
    }
    
    return self;
}

- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement {
    self = [super init];
    
    if (self) {
        const char *originChars = (const char *)sqlite3_column_text(statement, ZBRepoColumnOrigin);
        const char *descriptionChars = (const char *)sqlite3_column_text(statement, ZBRepoColumnDescription);
        const char *baseFilenameChars = (const char *)sqlite3_column_text(statement, ZBRepoColumnBaseFilename);
        const char *baseURLChars = (const char *)sqlite3_column_text(statement, ZBRepoColumnBaseURL);
        const char *suiteChars = (const char *)sqlite3_column_text(statement, ZBRepoColumnSuite);
        const char *compChars = (const char *)sqlite3_column_text(statement, ZBRepoColumnComponents);
        
        NSURL *iconURL;
        NSString *baseURL = baseURLChars != 0 ? [[NSString alloc] initWithUTF8String:baseURLChars] : NULL;
        NSArray *separate = [baseURL componentsSeparatedByString:@"dists"];
        NSString *shortURL = separate[0];
        
        BOOL secure = sqlite3_column_int(statement, ZBRepoColumnSecure);
        NSString *url = [baseURL stringByAppendingPathComponent:@"CydiaIcon.png"];
        if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) {
            iconURL = [NSURL URLWithString:url];
        } else if (secure) {
            iconURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", url]];
        } else {
            iconURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", url]];
        }
        
        [self setDesc:descriptionChars != 0 ? [[NSString alloc] initWithUTF8String:descriptionChars] : NULL];
        [self setBaseFileName:baseFilenameChars != 0 ? [[NSString alloc] initWithUTF8String:baseFilenameChars] : NULL];
        [self setBaseURL:baseURL];
        [self setOrigin:originChars != 0 ? [[NSString alloc] initWithUTF8String:originChars] : (baseURL ?: @"Unknown")];
        [self setSecure:secure];
        [self setRepoID:sqlite3_column_int(statement, ZBRepoColumnRepoID)];
        [self setIconURL:iconURL];
        [self setDefaultRepo:sqlite3_column_int(statement, ZBRepoColumnDef)];
        [self setSuite:suiteChars != 0 ? [[NSString alloc] initWithUTF8String:suiteChars] : NULL];
        [self setComponents:compChars != 0 ? [[NSString alloc] initWithUTF8String:compChars] : NULL];
        [self setShortURL:shortURL];
        if (secure) {
            NSString *requestURL;
            if ([baseURL hasSuffix:@"/"]) {
                requestURL = [NSString stringWithFormat:@"https://%@payment_endpoint", baseURL];
            } else {
                requestURL = [NSString stringWithFormat:@"https://%@/payment_endpoint", baseURL];
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
                            keychain[baseURL] = endpoint;
                            [self setSupportSileoPay:YES];
                        }
                    }] resume];
        }
        // prevent constant network spam
        if (!self.checkedSupportFeaturedPackages) {
            // Check for featured string
            NSString *requestURL;
            if ([baseURL hasSuffix:@"/"]) {
                requestURL = [NSString stringWithFormat:@"https://%@sileo-featured.json", baseURL];
            } else {
                requestURL = [NSString stringWithFormat:@"https://%@/sileo-featured.json", baseURL];
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

- (BOOL)isSecure {
    return secure;
}

- (BOOL)canDelete {
    return ![[self origin] isEqualToString:@"xTM3x Repo"];
}

- (BOOL)isEqual:(ZBRepo *)object {
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[ZBRepo class]])
        return NO;
    
    return ([[object baseFileName] isEqual:[self baseFileName]]);
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ %@ %d", origin, shortURL, repoID];
}

@end
