//
//  ZBTokenManager.m
//  Zebra
//
//  Created by Adam Demasi on 20/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBTokenManager.h"
#import "ZBAppDelegate.h"
@import Security;
@import LocalAuthentication;

NSErrorDomain const ZBTokenManagerErrorDomain = @"ZBTokenManagerErrorDomain";

@implementation ZBTokenManager

+ (NSString *)_service {
    return [ZBAppDelegate bundleID];
}

+ (SecAccessControlRef)_biometricAccessControl {
    return SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                           kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                           kSecAccessControlUserPresence,
                                           nil);
}

+ (NSError *)_errorForOSStatus:(OSStatus)status {
    NSString *description = [NSString stringWithFormat:@"Error %i", (int)status];
    if (@available(iOS 11.3, *)) {
        description = (NSString *)CFBridgingRelease(SecCopyErrorMessageString(status, nil));
    }
    return [NSError errorWithDomain:ZBTokenManagerErrorDomain code:status userInfo:@{
        NSLocalizedDescriptionKey: description
    }];
}

+ (NSMutableDictionary <NSString *, id> *)_queryForKey:(NSString *)key {
    return [NSMutableDictionary dictionaryWithDictionary:@{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrService: self._service,
        (__bridge NSString *)kSecAttrAccount: key
    }];
}

+ (BOOL)canUseBiometricWithError:(NSError * __autoreleasing *)error {
    LAContext *authContext = [[LAContext alloc] init];
    return [authContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:error];
}

+ (nullable NSString *)valueForKey:(NSString *)key {
    return [self _valueForKey:key withPrompt:nil error:nil];
}

+ (void)valueForKey:(NSString *)key withPrompt:(NSString *)prompt completion:(ZBTokenManagerValueForKeyCompletion)completion {
    __block NSString *value;
    __block NSError *error;
    if (prompt && ![self canUseBiometricWithError:&error]) {
        completion(nil, error);
        return;
    }

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_queue_create("xyz.willy.Zebra.token-manager-queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0));
    dispatch_async(queue, ^{
        value = [self _valueForKey:key withPrompt:prompt error:&error];
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    completion(value, error);
}

+ (nullable NSString *)_valueForKey:(NSString *)key withPrompt:(nullable NSString *)prompt error:(NSError * __autoreleasing *)error {
    NSMutableDictionary <NSString *, id> *query = [self _queryForKey:key];
    [query addEntriesFromDictionary:@{
        (__bridge NSString *)kSecMatchLimit: (__bridge NSString *)kSecMatchLimitOne,
        (__bridge NSString *)kSecReturnData: @YES,
        (__bridge NSString *)kSecUseAuthenticationUI: (__bridge NSString *)(prompt ? kSecUseAuthenticationUIAllow : kSecUseAuthenticationUIFail)
    }];
    if (prompt) {
        [query addEntriesFromDictionary:@{
            (__bridge NSString *)kSecUseOperationPrompt: prompt,
            (__bridge NSString *)kSecAttrAccessControl: (id)self._biometricAccessControl
        }];
    }

    CFTypeRef data;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &data);
    switch (status) {
    case errSecSuccess:
        return [[NSString alloc] initWithData:(NSData *)CFBridgingRelease(data)
                                     encoding:NSUTF8StringEncoding];

    case errSecItemNotFound:
        return nil;

    default:
        if (error) {
            *error = [self _errorForOSStatus:status];
        }
        return nil;
    }
}

+ (BOOL)setValue:(NSString *)value forKey:(NSString *)key requireBiometric:(BOOL)requireBiometric error:(NSError * __autoreleasing *)error {
    NSParameterAssert(key);

    if (!value) {
        return [self removeValueForKey:key error:error];
    }

    if (requireBiometric && ![self canUseBiometricWithError:nil]) {
        // No biometric, can’t safely write value. Don’t do anything, but act like success.
        return YES;
    }

    NSMutableDictionary <NSString *, id> *query = [self _queryForKey:key];
    [query addEntriesFromDictionary:@{
        (__bridge NSString *)kSecValueData: [value dataUsingEncoding:NSUTF8StringEncoding],
        (__bridge NSString *)kSecReturnData: @YES,
        (__bridge NSString *)kSecAttrSynchronizable: @NO
    }];
    if (requireBiometric) {
        query[(__bridge NSString *)kSecAttrAccessControl] = (id)self._biometricAccessControl;
    }

    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, nil);
    if (status == errSecSuccess) {
        return YES;
    }

    if (error) {
        *error = [self _errorForOSStatus:status];
    }
    return NO;
}

+ (BOOL)containsKey:(NSString *)key {
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)[self _queryForKey:key], NULL);
    switch (status) {
    case errSecSuccess:
    case errSecInteractionNotAllowed:
        // Interaction not allowed means the entry exists, but is protected by biometric.
        return YES;

    default:
        return NO;
    }
}

+ (BOOL)removeValueForKey:(NSString *)key error:(NSError * __autoreleasing *)error {
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)[self _queryForKey:key]);
    switch (status) {
    case errSecSuccess:
    case errSecItemNotFound:
        return YES;

    default:
        if (error) {
            *error = [self _errorForOSStatus:status];
        }
        return NO;
    }
}

@end
