//
//  ZBTokenManager.h
//  Zebra
//
//  Created by Adam Demasi on 20/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const ZBTokenManagerErrorDomain;

typedef void (^ZBTokenManagerValueForKeyCompletion)(NSString * _Nullable value, NSError * _Nullable error);

@interface ZBTokenManager : NSObject

+ (BOOL)canUseBiometricWithError:(NSError * __autoreleasing *)error;

+ (nullable NSString *)valueForKey:(NSString *)key;
+ (void)valueForKey:(NSString *)key withPrompt:(NSString *)prompt completion:(ZBTokenManagerValueForKeyCompletion)completion;

+ (BOOL)setValue:(NSString *)value forKey:(NSString *)key requireBiometric:(BOOL)requireBiometric error:(NSError * __autoreleasing *)error;
+ (BOOL)containsKey:(NSString *)key;
+ (BOOL)removeValueForKey:(NSString *)key error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
