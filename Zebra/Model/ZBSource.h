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

@import Foundation;
@import SQLite3;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSource : ZBBaseSource
@property (readonly) NSArray <NSString *> *architectures;
@property (readonly) NSString *codename;
@property (readonly) NSString *origin;
@property (readonly) NSInteger pinPriority;
@property (readonly) NSString *sourceDescription;
@property (readonly) NSString *suite;
@property (readonly) NSString *version;

+ (ZBSource *)localSource;
+ (UIImage *)imageForSection:(NSString *)section;

#pragma mark - Initializers

- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement;

- (NSDictionary <NSString *, NSNumber *> *)sections;

#pragma mark - Featured Packages API

- (void)getFeaturedPackages:(void (^)(NSDictionary *_Nullable featuredPackages))completion;

#pragma mark - Modern Payment API

- (void)getPaymentEndpoint:(void (^)(NSURL *_Nullable paymentEndpointURL))completion;
- (NSString *)paymentSecret:(NSError **)error;
- (void)authenticate:(void (^)(BOOL success, BOOL notify, NSError *_Nullable error))completion;
- (void)signOut;
- (BOOL)isSignedIn;
- (BOOL)supportsPaymentAPI;
- (void)getUserInfo:(void (^)(ZBUserInfo *info, NSError *error))completion;
- (void)getSourceInfo:(void (^)(ZBSourceInfo *info, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
