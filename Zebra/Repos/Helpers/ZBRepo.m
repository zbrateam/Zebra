//
//  ZBRepo.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBRepo.h"
#import <ZBAppDelegate.h>

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

+ (ZBRepo *)repoMatchingRepoID:(int)repoID {
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM REPOS WHERE REPOID = %d;", repoID];
    
    sqlite3 *database;
    sqlite3_open([[ZBAppDelegate databaseLocation] UTF8String], &database);
    
    ZBRepo *source;
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        source = [[ZBRepo alloc] initWithSQLiteStatement:statement];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
    return source;
}

+ (ZBRepo *)localRepo {
    ZBRepo *local = [[ZBRepo alloc] init];
    [local setOrigin:@"Local Repository"];
    [local setDesc:@"Locally installed packages"];
    [local setRepoID:0];
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
        const char *originChars = (const char *)sqlite3_column_text(statement, 0);
        const char *descriptionChars = (const char *)sqlite3_column_text(statement, 1);
        const char *baseFilenameChars = (const char *)sqlite3_column_text(statement, 2);
        const char *baseURLChars = (const char *)sqlite3_column_text(statement, 3);
        const char *suiteChars = (const char *)sqlite3_column_text(statement, 7);
        const char *compChars = (const char *)sqlite3_column_text(statement, 8);
        
        NSURL *iconURL;
        NSString *baseURL = baseURLChars != 0 ? [[NSString alloc] initWithUTF8String:baseURLChars] : NULL;
        NSArray *separate = [baseURL componentsSeparatedByString:@"dists"];
        NSString *shortURL = separate[0];
        
        BOOL secure = sqlite3_column_int(statement, 4);
        NSString *url = [baseURL stringByAppendingPathComponent:@"CydiaIcon.png"];
        if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) {
            iconURL = [NSURL URLWithString:url] ;
        }
        else if (secure) {
            iconURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", url]];
        }
        else {
            iconURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", url]];
        }
        
        [self setOrigin:originChars != 0 ? [[NSString alloc] initWithUTF8String:originChars] : NULL];
        [self setDesc:descriptionChars != 0 ? [[NSString alloc] initWithUTF8String:descriptionChars] : NULL];
        [self setBaseFileName:baseFilenameChars != 0 ? [[NSString alloc] initWithUTF8String:baseFilenameChars] : NULL];
        [self setBaseURL:baseURL];
        [self setSecure:secure];
        [self setRepoID:sqlite3_column_int(statement, 5)];
        [self setIconURL:iconURL];
        [self setDefaultRepo:sqlite3_column_int(statement, 6)];
        [self setSuite:suiteChars != 0 ? [[NSString alloc] initWithUTF8String:suiteChars] : NULL];
        [self setComponents:compChars != 0 ? [[NSString alloc] initWithUTF8String:compChars] : NULL];
        [self setShortURL:shortURL];
    }
    
    return self;
}

- (BOOL)isSecure {
    return secure;
}

- (BOOL)isEqual:(ZBRepo *)object {
    if (self == object)
        return TRUE;
    
    if (![object isKindOfClass:[ZBRepo class]])
        return FALSE;
    
    return ([[object baseFileName] isEqual:[self baseFileName]]);
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ %@ %d", origin, shortURL, repoID];
}

@end
