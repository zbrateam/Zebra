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

@property (nonatomic, readonly, nullable) NSString *token;

- (void)getPaymentSecret:(void (^)(NSString * _Nullable value, NSError * _Nullable error))completion;
- (void)clearKeychainEntries;

- (void)authenticate:(void (^)(BOOL success, BOOL notify, NSError * _Nullable error))completion;
- (void)signOut;

- (void)getSourceInfo:(void (^)(ZBSourceInfo * _Nullable info, NSError * _Nullable error))completion;
- (void)getUserInfo:(void (^)(ZBUserInfo * _Nullable info, NSError * _Nullable error))completion;

- (void)getInfoForPackage:(NSString *)packageID completion:(void (^)(ZBPurchaseInfo * _Nullable info, NSError * _Nullable error))completion;
- (void)initiatePurchaseForPackage:(NSString *)packageID paymentSecret:(nullable NSString *)paymentSecret completion:(void (^)(NSError * _Nullable error))completion;

- (void)authorizeDownloadForPackage:(NSString *)packageID params:(NSDictionary <NSString *, id> *)params completion:(void (^)(NSURL * _Nullable url, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
