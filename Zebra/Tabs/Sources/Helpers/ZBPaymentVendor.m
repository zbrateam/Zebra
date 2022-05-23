//
//  ZBPaymentVendor.m
//  Zebra
//
//  Created by Adam Demasi on 18/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBPaymentVendor.h"
#import "ZBAppDelegate.h"
#import "ZBDevice.h"
#import "ZBUserInfo.h"
#import "ZBSource.h"
#import "ZBSourceManager.h"
#import "ZBSourceInfo.h"
#import "ZBSafariAuthenticationSession.h"
#import "ZBDownloadManager.h"
#import "ZBPurchaseInfo.h"
#import "ZBPaymentVendorError.h"
#import "ZBTokenManager.h"
#import "NSURLSession+Zebra.h"
@import LocalAuthentication;

NSErrorDomain const ZBPaymentVendorErrorDomain = @"ZBPaymentVendorErrorDomain";

NSErrorUserInfoKey const ZBPaymentVendorErrorRecoveryURL = @"ZBPaymentVendorErrorRecoveryURL";

typedef void (^ZBPaymentVendorCompletionHandler)(NSHTTPURLResponse *response, id body, NSError *error);

@implementation ZBPaymentVendor {
    NSURL *_paymentVendorURL;
    NSURLSession *_urlSession;
}

- (instancetype)initWithRepositoryURI:(NSString *)repositoryURI paymentVendorURL:(NSURL *)paymentVendorURL {
    self = [super init];
    if (self) {
        _repositoryURI = [repositoryURI copy];
        _paymentVendorURL = [paymentVendorURL copy];
        _urlSession = [NSURLSession zbra_standardSession];
    }
    return self;
}

- (ZBSource *)source {
    for (ZBSource *source in [ZBSourceManager sharedInstance].sources.allValues) {
        if ([source.repositoryURI isEqualToString:_repositoryURI]) {
            return source;
        }
    }
    return nil;
}

- (BOOL)supportsPaymentAPI {
    return _paymentVendorURL && _paymentVendorURL.host && [_paymentVendorURL.scheme isEqualToString:@"https"];
}

- (NSMutableURLRequest *)_requestWithMethod:(NSString *)method path:(NSString *)path body:(nullable NSDictionary *)body {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[_paymentVendorURL URLByAppendingPathComponent:path]];
    request.HTTPMethod = method;
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    if (![method isEqualToString:@"GET"] && body) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:kNilOptions error:nil];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)request.HTTPBody.length] forHTTPHeaderField:@"Content-Length"];
    }
#if DEBUG
    NSLog(@"[PaymentVendor] Request: %@ %@", method, request.URL);
#endif
    return request;
}

- (nullable NSError *)_errorWithBody:(NSData *)body response:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSError *error2;
    ZBPaymentVendorError *error = [ZBPaymentVendorError fromData:body error:&error2];
    if (error && (error.error || error.recoveryURL || error.invalidate)) {
        if (error.invalidate) {
            [self signOut];
        }

        NSMutableDictionary <NSErrorUserInfoKey, id> *userInfo = [NSMutableDictionary dictionary];
        userInfo[NSLocalizedDescriptionKey] = error.error ?: NSLocalizedString(@"The Payment Provider returned an unspecified error", @"");
        if (error.recoveryURL) {
            userInfo[ZBPaymentVendorErrorRecoveryURL] = error.recoveryURL;
        }
        return [NSError errorWithDomain:ZBPaymentVendorErrorDomain code:0 userInfo:userInfo];
    }
    if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        return nil;
    }
    return [ZBDownloadManager errorForHTTPStatusCode:httpResponse.statusCode forFile:nil];
}

- (nullable NSString *)token {
    return [ZBTokenManager valueForKey:self.repositoryURI];
}

- (BOOL)isSignedIn {
    return self.token != nil;
}

- (void)getPaymentSecret:(void (^)(NSString * _Nullable value, NSError * _Nullable error))completion {
    NSString *paymentKeychainIdentifier = [NSString stringWithFormat:@"%@payment", [self repositoryURI]];
    [ZBTokenManager valueForKey:paymentKeychainIdentifier
                     withPrompt:NSLocalizedString(@"Authenticate to initiate purchase.", @"")
                     completion:^(NSString * _Nullable value, NSError * _Nullable error) {
        // Payment secret is only applicable if the device is passcode protected, so we ignore
        // passcode not set error.
        if (error && (error.domain != LAErrorDomain || error.code != LAErrorPasscodeNotSet)) {
            NSLog(@"[PaymentVendor] Failed to get payment secret: %@", error);
            completion(nil, error);
            return;
        }
        completion(value, nil);
    }];
}

- (BOOL)hasPaymentSecret {
    return [ZBTokenManager containsKey:[NSString stringWithFormat:@"%@payment", self.repositoryURI]];
}

- (void)clearKeychainEntries {
    [ZBTokenManager removeValueForKey:self.repositoryURI error:nil];
    [ZBTokenManager removeValueForKey:[NSString stringWithFormat:@"%@payment", self.repositoryURI] error:nil];
}

- (void)authenticate:(void (^)(BOOL success, BOOL notify, NSError *_Nullable error))completion {
    if (![self supportsPaymentAPI]) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:412 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Source does not support Payment API", @"")}];
        completion(NO, YES, error);
        return;
    }

    if ([self isSignedIn] && [self hasPaymentSecret]) {
        completion(YES, NO, nil);
        return;
    }

    // Sign out in the background, in case the provider is signed in but payment secret was missing.
    [self signOut];

    NSURLComponents *components = [NSURLComponents componentsWithURL:[_paymentVendorURL URLByAppendingPathComponent:@"authenticate"] resolvingAgainstBaseURL:YES];
    if (![components.scheme isEqualToString:@"https"]) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:412 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Source's payment vendor URL is not secure", @"")}];
        completion(NO, YES, error);
        return;
    }

    NSMutableArray *queryItems = [[components queryItems] mutableCopy] ?: [NSMutableArray array];
    [queryItems addObjectsFromArray:@[
        [NSURLQueryItem queryItemWithName:@"udid" value:[ZBDevice UDID]],
        [NSURLQueryItem queryItemWithName:@"model" value:[ZBDevice deviceModelID]]
    ]];
    components.queryItems = queryItems;

    static ZBSafariAuthenticationSession *session;
    session = [[ZBSafariAuthenticationSession alloc] initWithURL:components.URL callbackURLScheme:@"sileo" completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
        if (callbackURL && !error) {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:callbackURL resolvingAgainstBaseURL:NO];
            NSArray *queryItems = urlComponents.queryItems;
            NSMutableDictionary *queryByKeys = [NSMutableDictionary new];
            for (NSURLQueryItem *q in queryItems) {
                [queryByKeys setValue:[q value] forKey:[q name]];
            }
            NSString *token = queryByKeys[@"token"];
            NSString *payment = queryByKeys[@"payment_secret"];

            NSString *paymentKeychainIdentifier = [NSString stringWithFormat:@"%@payment", self.repositoryURI];
            NSError *tokenError;
            [ZBTokenManager setValue:token forKey:self.repositoryURI requireBiometric:NO error:&tokenError];
            [ZBTokenManager setValue:payment forKey:paymentKeychainIdentifier requireBiometric:YES error:&tokenError];
            if (tokenError) {
                completion(NO, YES, error);
            } else {
                completion(YES, NO, NULL);
            }
        }
        else if (error) {
            completion(NO, !(error.domain == ZBSafariAuthenticationErrorDomain && error.code == ZBSafariAuthenticationErrorCanceledLogin), error);
        }
    }];
    [session start];
}

- (void)signOut {
    NSString *token = self.token;
    [self clearKeychainEntries];

    if (![self supportsPaymentAPI] || ![self isSignedIn]) {
        return;
    }

    // Silently fail if there is an error
    NSMutableURLRequest *request = [self _requestWithMethod:@"POST" path:@"sign_out" body:@{
        @"token": token ?: @"none"
    }];
    [[_urlSession dataTaskWithRequest:request] resume];
}

- (void)getSourceInfo:(void (^)(ZBSourceInfo *info, NSError *error))completion {
    if (!_paymentVendorURL) return;

    NSMutableURLRequest *request = [self _requestWithMethod:@"GET" path:@"info" body:nil];
    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        error = error ?: [self _errorWithBody:data response:response];
        if (error) {
            completion(nil, error);
            return;
        }

        NSError *parseError;
        ZBSourceInfo *sourceInfo = [ZBSourceInfo fromData:data error:&parseError];
        if (parseError) {
            completion(nil, parseError);
            return;
        }
        completion(sourceInfo, nil);
    }] resume];
}

- (void)getUserInfo:(void (^)(ZBUserInfo *info, NSError *error))completion {
    if (!_paymentVendorURL || ![self isSignedIn]) return;

    NSDictionary *requestJSON = @{
        @"token": self.token,
        @"udid": [ZBDevice UDID],
        @"device": [ZBDevice deviceModelID]
    };
    NSMutableURLRequest *request = [self _requestWithMethod:@"POST" path:@"user_info" body:requestJSON];
    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        error = error ?: [self _errorWithBody:data response:response];
        if (error) {
            completion(nil, error);
            return;
        }

        NSError *parseError;
        ZBUserInfo *userInfo = [ZBUserInfo fromData:data error:&parseError];
        if (parseError) {
            completion(nil, parseError);
            return;
        }
        completion(userInfo, nil);
    }] resume];
}

- (void)getInfoForPackage:(NSString *)packageID completion:(void (^)(ZBPurchaseInfo *info, NSError *error))completion {
    ZBSource *source = self.source;
    NSString *token = self.token;

    // Attempt GET when logged out. Helps the payment provider cache the unauthenticated response
    // when the UDID/model are not needed.
    BOOL attemptGET = !token && (!source.checkedSupportGETPackageInfo || source.supportsGETPackageInfo);
    NSMutableDictionary *body = nil;
    if (!attemptGET) {
        body = [NSMutableDictionary dictionaryWithDictionary:@{
            @"udid": [ZBDevice UDID],
            @"device": [ZBDevice deviceModelID]
        }];
        if (token) {
            body[@"token"] = token;
        }
    }
    NSMutableURLRequest *request = [self _requestWithMethod:attemptGET ? @"GET" : @"POST"
                                                       path:[NSString stringWithFormat:@"package/%@/info", packageID]
                                                       body:body];
    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (attemptGET) {
            self.source.checkedSupportGETPackageInfo = YES;
        }

        error = error ?: [self _errorWithBody:data response:response];
        if (error || data == nil) {
            if (attemptGET) {
                // Retry as POST.
                self.source.supportsGETPackageInfo = NO;
                [self getInfoForPackage:packageID completion:completion];
            } else {
                completion(nil, error);
            }
            return;
        }

        ZBPurchaseInfo *info = [ZBPurchaseInfo fromData:data error:&error];
        if (error) {
            if (attemptGET) {
                // Retry as POST.
                self.source.supportsGETPackageInfo = NO;
                [self getInfoForPackage:packageID completion:completion];
            } else {
                completion(nil, error);
            }
            return;
        }
        completion(info, nil);
    }] resume];
}

- (void)initiatePurchaseForPackage:(NSString *)packageID paymentSecret:(nullable NSString *)paymentSecret completion:(void (^)(NSError *_Nullable error))completion {
    NSDictionary *body = @{
        @"token": self.token,
        @"payment_secret": paymentSecret ?: [NSNull null],
        @"udid": [ZBDevice UDID],
        @"device": [ZBDevice deviceModelID]
    };
    NSMutableURLRequest *request = [self _requestWithMethod:@"POST"
                                                       path:[NSString stringWithFormat:@"package/%@/purchase", packageID]
                                                       body:body];
    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        error = error ?: [self _errorWithBody:data response:response];
        if (error) {
            completion(error);
            return;
        }

        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        NSInteger status = [result[@"status"] integerValue];
        switch (status) {
        case -1: { // An error occurred, payment api doesn't specify that an error must exist here but we may as well check it
            NSString *localizedDescription = [result objectForKey:@"error"] ?: NSLocalizedString(@"The Payment Provider returned an unspecified error", @"");

            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:505 userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
            completion(error);
            break;
        }
        case 0: { // Success, queue the package for install
            completion(nil);
            break;
        }
        case 1: { // Action is required, pass this information on to the view controller
            NSURL *actionLink = [NSURL URLWithString:result[@"url"]];
            if (actionLink && actionLink.host && ([actionLink.scheme isEqualToString:@"https"])) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    static ZBSafariAuthenticationSession *session;
                    session = [[ZBSafariAuthenticationSession alloc] initWithURL:actionLink callbackURLScheme:@"sileo" completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
                        if (callbackURL && !error) {
                            completion(nil);
                        }
                        else if (error && !(error.domain == ZBSafariAuthenticationErrorDomain && error.code == ZBSafariAuthenticationErrorCanceledLogin)) {
                            NSString *localizedDescription = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Could not complete purchase", @""), error.localizedDescription];

                            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:505 userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
                            completion(error);
                        }
                    }];
                    [session start];
                });
            }
            else {
                NSString *localizedDescription = [NSString stringWithFormat:NSLocalizedString(@"The Payment Provider responded with an improper payment URL: %@", @""), result[@"url"]];

                NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:505 userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
                completion(error);
            }
            break;
        }
        }
    }] resume];
}

- (void)authorizeDownloadForPackage:(NSString *)packageID params:(NSDictionary <NSString *, id> *)params completion:(void (^)(NSURL * _Nullable url, NSError * _Nullable error))completion {
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithDictionary:@{
        @"token": self.token ?: @"none",
        @"udid": [ZBDevice UDID],
        @"device": [ZBDevice deviceModelID]
    }];
    [body addEntriesFromDictionary:params];

    NSMutableURLRequest *request = [self _requestWithMethod:@"POST"
                                                       path:[NSString stringWithFormat:@"package/%@/authorize_download", packageID]
                                                       body:body];
    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        error = error ?: [self _errorWithBody:data response:response];
        if (error) {
            completion(nil, error);
            return;
        }

        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        if (!result[@"url"]) {
            error = [NSError errorWithDomain:ZBPaymentVendorErrorDomain
                                        code:808
                                    userInfo:@{
                NSLocalizedDescriptionKey: @"Did not receive download URL for paid package"
            }];
            completion(nil, error);
            return;
        }

        NSURL *downloadURL = [NSURL URLWithString:result[@"url"]];
        if (downloadURL && [downloadURL.scheme isEqualToString:@"https"]) {
            completion(downloadURL, nil);
            return;
        }
        error = [NSError errorWithDomain:ZBPaymentVendorErrorDomain
                                    code:808
                                userInfo:@{
            NSLocalizedDescriptionKey: @"Couldn’t parse download URL for paid package"
        }];
        completion(nil, error);
    }] resume];
}

@end
