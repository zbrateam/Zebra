//
//  ZBSource.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@class UIImage;
@class ZBPaymentVendor;

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
@property (nonatomic) int sourceID;

@property (nonatomic) BOOL supportsFeaturedPackages;
@property (nonatomic) BOOL checkedSupportFeaturedPackages;
@property (nonatomic) BOOL supportsGETPackageInfo;
@property (nonatomic) BOOL checkedSupportGETPackageInfo;
@property (nonatomic) NSURL *iconURL;

@property (nonatomic, strong) ZBPaymentVendor *paymentVendor;

+ (ZBSource *)sourceMatchingSourceID:(int)sourceID;
+ (ZBSource *)localSource:(int)sourceID;
+ (ZBSource *)sourceFromBaseURL:(NSString *)baseURL;
+ (ZBSource * _Nullable)sourceFromBaseFilename:(NSString *)baseFilename;
+ (BOOL)exists:(NSString *)urlString;
+ (UIImage *)imageForSection:(NSString *)section;
- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement;

#pragma mark - Modern Payment API

- (NSURL *)paymentVendorURL;
- (BOOL)supportsPaymentAPI;

@end

NS_ASSUME_NONNULL_END
