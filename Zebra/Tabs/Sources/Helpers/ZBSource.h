//
//  ZBSource.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@class UIImage;
@class ZBUserInfo;
@class ZBSourceInfo;

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

@property (nonatomic) BOOL supportsFeaturedPackages;
@property (nonatomic) BOOL checkedSupportFeaturedPackages;
@property (nonatomic) NSURL *iconURL;

+ (ZBSource *)repoMatchingRepoID:(int)repoID;
+ (ZBSource *)localRepo:(int)repoID;
+ (ZBSource *)repoFromBaseURL:(NSString *)baseURL;
+ (ZBSource * _Nullable)sourceFromBaseFilename:(NSString *)baseFilename;
+ (BOOL)exists:(NSString *)urlString;
+ (UIImage *)imageForSection:(NSString *)section;
- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement;

#pragma mark - Modern Payment API

- (NSString *)paymentSecret API_AVAILABLE(ios(11.0));
- (void)authenticate:(void (^)(BOOL success, NSError *_Nullable error))completion API_AVAILABLE(ios(11.0));
- (BOOL)isSignedIn API_AVAILABLE(ios(11.0));
- (NSURL *)paymentVendorURL API_AVAILABLE(ios(11.0));
- (BOOL)suppotsPaymentAPI API_AVAILABLE(ios(11.0));
- (void)getUserInfo:(void (^)(ZBUserInfo *info, NSError *error))completion API_AVAILABLE(ios(11.0));
- (void)getSourceInfo:(void (^)(ZBSourceInfo *info, NSError *error))completion API_AVAILABLE(ios(11.0));

@end

NS_ASSUME_NONNULL_END
