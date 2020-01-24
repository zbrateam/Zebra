//
//  ZBSource.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBBaseSource.h"

#import <Foundation/Foundation.h>
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSource : ZBBaseSource
@property (nonatomic) NSString *sourceDescription;
@property (nonatomic) NSString *origin;
@property (nonatomic) NSString *version;
@property (nonatomic) NSString *suite;
@property (nonatomic) NSString *codename;
@property (nonatomic) NSArray <NSString *> *architectures;
@property (nonatomic) int repoID;

@property (nonatomic) NSURL *paymentVendorURL;
@property (nonatomic) BOOL supportsFeaturedPackages;
@property (nonatomic) BOOL checkedSupportFeaturedPackages;
@property (nonatomic) NSURL *iconURL;

+ (ZBSource *)repoMatchingRepoID:(int)repoID;
+ (ZBSource *)localRepo:(int)repoID;
+ (ZBSource *)repoFromBaseURL:(NSString *)baseURL;
+ (BOOL)exists:(NSString *)urlString;
- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement;
- (NSString *)paymentSecret;
@end

NS_ASSUME_NONNULL_END
