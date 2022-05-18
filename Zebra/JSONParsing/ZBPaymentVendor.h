//
//  ZBPaymentVendor.h
//  Zebra
//
//  Created by Adam Demasi on 18/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZBUserInfo, ZBSourceInfo, ZBPurchaseInfo;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSErrorDomain const ZBPaymentVendorErrorDomain;

FOUNDATION_EXTERN NSErrorUserInfoKey const ZBPaymentVendorErrorRecoveryURLKey;

@interface ZBPaymentVendor : NSObject

- (instancetype)initWithRepositoryURI:(NSString *)repositoryURI paymentVendorURL:(NSURL *)paymentVendorURL;

@property (nonatomic, strong, readonly) NSString *repositoryURI;

@property (nonatomic, readonly) BOOL supportsPaymentAPI;
@property (nonatomic, readonly) BOOL isSignedIn;

- (nullable NSString *)paymentSecret:(NSError **)error;

- (void)clearKeychainEntries;

- (void)authenticate:(void (^)(BOOL success, BOOL notify, NSError *_Nullable error))completion;
- (void)signOut;

- (void)getSourceInfo:(void (^)(ZBSourceInfo *info, NSError *error))completion;
- (void)getUserInfo:(void (^)(ZBUserInfo *info, NSError *error))completion;

- (void)getInfoForPackage:(NSString *)packageID completion:(void (^)(ZBPurchaseInfo *info, NSError *error))completion;
- (void)initiatePurchaseForPackage:(NSString *)packageID paymentSecret:(nullable NSString *)paymentSecret completion:(void (^)(NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
