//
//  ZBRepo.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBRepo : NSObject
@property (nonatomic, strong) NSString *origin;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *baseFileName;
@property (nonatomic, strong) NSString *baseURL;
@property (nonatomic) BOOL secure;
@property (nonatomic) int repoID;
@property (nonatomic, strong) NSURL *iconURL;
@property (nonatomic) BOOL defaultRepo;
@property (nonatomic, strong) NSString *suite;
@property (nonatomic, strong) NSString *components;
@property (nonatomic, strong) NSString *shortURL;

+ (ZBRepo *)repoMatchingRepoID:(int)repoID;
+ (ZBRepo *)localRepo;
- (id)initWithOrigin:(NSString *)origin description:(NSString *)description baseFileName:(NSString *)bfn baseURL:(NSString *)baseURL secure:(BOOL)sec repoID:(int)repoIdentifier iconURL:(NSURL *)icoURL isDefault:(BOOL)isDefault suite:(NSString *)sweet components:(NSString *)comp shortURL:(NSString *)shortA;
- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement;
- (BOOL)isSecure;
@end

NS_ASSUME_NONNULL_END
