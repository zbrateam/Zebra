//
//  ZBSource.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@import UIKit;
@import SafariServices;

#import "ZBSource.h"
#import "ZBSourceManager.h"
#import "UICKeyChainStore.h"
#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <JSONParsing/ZBUserInfo.h>
#import <JSONParsing/ZBSourceInfo.h>
#import <Tabs/ZBTabBarController.h>

#import <Managers/ZBSourceManager.h>

@interface ZBSource () {
    NSDictionary *featuredPackages;
}
@end

@implementation ZBSource

@synthesize pinPriority = _pinPriority;

+ (ZBSource *)localSource {
    ZBSource *local = [[super alloc] initFromURL:[NSURL fileURLWithPath:@"/var/lib/dpkg/status"]];
    
    return local;
}

+ (UIImage *)imageForSection:(NSString *)section {
    if (!section) return [UIImage imageNamed:@"Unknown"];
    
    NSString *imageName = [section stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    if ([imageName containsString:@"("]) {
        NSArray *components = [imageName componentsSeparatedByString:@"_("];
        if ([components count] < 2) {
            components = [imageName componentsSeparatedByString:@"("];
        }
        imageName = components[0];
    }
    
    UIImage *sectionImage = [UIImage imageNamed:imageName] ?: [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Applications/Zebra.app/Sections/%@.png", imageName]] ?: [UIImage imageNamed:@"Unknown"];
    return sectionImage;
}

- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement {
    const char *archiveType     = (const char *)sqlite3_column_text(statement, ZBSourceColumnArchiveType);
    const char *repositoryURI   = (const char *)sqlite3_column_text(statement, ZBSourceColumnURL);
    const char *distribution    = (const char *)sqlite3_column_text(statement, ZBSourceColumnDistribution);
    const char *componentsChars = (const char *)sqlite3_column_text(statement, ZBSourceColumnComponents);
    
    if (repositoryURI == 0) return NULL;
    
    NSArray *components;
    if (componentsChars != 0 && strcmp(componentsChars, "") != 0) {
        components = [[NSString stringWithUTF8String:componentsChars] componentsSeparatedByString:@" "];
    }
    
    self = [super initWithArchiveType:archiveType != 0 ? [NSString stringWithUTF8String:archiveType] : @"deb" repositoryURI:[NSString stringWithUTF8String:repositoryURI] distribution:distribution != 0 ? [NSString stringWithUTF8String:distribution] : @"./" components:components];
    
    if (self) {
        const char *architectures = (const char *)sqlite3_column_text(statement, ZBSourceColumnArchitectures);
        if (architectures) {
            _architectures = [[NSString stringWithUTF8String:architectures] componentsSeparatedByString:@" "];
        }
        
        const char *codename = (const char *)sqlite3_column_text(statement, ZBSourceColumnCodename);
        if (codename) {
            _codename = [NSString stringWithUTF8String:codename];
        }
        
        const char *description = (const char *)sqlite3_column_text(statement, ZBSourceColumnDescription);
        if (description) {
            _sourceDescription = [NSString stringWithUTF8String:description];
        }
        
        const char *label = (const char *)sqlite3_column_text(statement, ZBSourceColumnLabel);
        if (label) {
            self.label = [NSString stringWithUTF8String:label];
        }
        
        const char *origin = (const char *)sqlite3_column_text(statement, ZBSourceColumnOrigin);
        if (origin) {
            self.origin = [NSString stringWithUTF8String:origin];
        }
        
        const char *paymentEndpoint = (const char *)sqlite3_column_text(statement, ZBSourceColumnPaymentEndpoint);
        if (paymentEndpoint) {
            NSURL *endpointURL = [NSURL URLWithString:[NSString stringWithUTF8String:paymentEndpoint]];
            if ([endpointURL.scheme isEqual:@"https"]) self.paymentEndpointURL = endpointURL;
        }
        
        const char *suite = (const char *)sqlite3_column_text(statement, ZBSourceColumnSuite);
        if (suite) {
            _suite = [NSString stringWithUTF8String:suite];
        }
        
        self.supportsFeaturedPackages = sqlite3_column_int(statement, ZBSourceColumnSupportsFeaturedPackages);
        
        const char *version = (const char *)sqlite3_column_text(statement, ZBSourceColumnVersion);
        if (version) {
            _version = [NSString stringWithUTF8String:version];
        }
        
        _pinPriority = [[ZBSourceManager sharedInstance] pinPriorityForSource:self];
    }
    
    return self;
}

- (BOOL)canDelete {
    return ![[self uuid] isEqualToString:@"getzbra.com_repo_"];
}

- (void)authenticate:(void (^)(BOOL success, BOOL notify, NSError *_Nullable error))completion {
    if (![self supportsPaymentAPI]) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:412 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Source does not support Payment API", @"")}];
        completion(NO, YES, error);
        return;
    }
    
    if ([self isSignedIn]) {
        completion(YES, NO, nil);
        return;
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:[self.paymentEndpointURL URLByAppendingPathComponent:@"authenticate"] resolvingAgainstBaseURL:YES];
    if (![components.scheme isEqualToString:@"https"]) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:412 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Source's payment vendor URL is not secure", @"")}];
        completion(NO, YES, error);
        return;
    }
    
    NSMutableArray *queryItems = [components queryItems] ? [[components queryItems] mutableCopy] : [NSMutableArray new];
    NSURLQueryItem *udid = [NSURLQueryItem queryItemWithName:@"udid" value:[ZBDevice UDID]];
    NSURLQueryItem *model = [NSURLQueryItem queryItemWithName:@"model" value:[ZBDevice deviceModelID]];
    [queryItems addObject:udid];
    [queryItems addObject:model];
    [components setQueryItems:queryItems];
    
    NSURL *url = [components URL];
    static SFAuthenticationSession *session;
    session = [[SFAuthenticationSession alloc] initWithURL:url callbackURLScheme:@"sileo" completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
        if (callbackURL && !error) {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:callbackURL resolvingAgainstBaseURL:NO];
            NSArray *queryItems = urlComponents.queryItems;
            NSMutableDictionary *queryByKeys = [NSMutableDictionary new];
            for (NSURLQueryItem *q in queryItems) {
                [queryByKeys setValue:[q value] forKey:[q name]];
            }
            NSString *token = queryByKeys[@"token"];
            NSString *payment = queryByKeys[@"payment_secret"];
            
            UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
            [keychain setString:token forKey:self.repositoryURI];
            
            NSString *key = [self.repositoryURI stringByAppendingString:@"payment"];
            [keychain setString:nil forKey:key];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [keychain setAccessibility:UICKeyChainStoreAccessibilityWhenPasscodeSetThisDeviceOnly
                      authenticationPolicy:UICKeyChainStoreAuthenticationPolicyUserPresence];
                
                [keychain setString:payment forKey:key];
                
                completion(YES, NO, NULL);
            });
        }
        else if (error) {
            completion(NO, !(error.domain == SFAuthenticationErrorDomain && error.code == SFAuthenticationErrorCanceledLogin), error);
            return;
        }
    }];
    
    [session start];
}

- (void)signOut API_AVAILABLE(ios(11.0)) {
    if (![self supportsPaymentAPI]) {
//        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:412 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Source does not support Payment API", @"")}];
        return;
    }
    
    if (![self isSignedIn]) {
        return;
    }
    
    NSURL *URL = [self.paymentEndpointURL URLByAppendingPathComponent:@"sign_out"];
    if (!URL || ![URL.scheme isEqualToString:@"https"]) {
//        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:412 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Source's payment vendor URL is not secure", @"")}];
        return;
    }
    
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    NSDictionary *question = @{@"token": [keychain stringForKey:[self repositoryURI]] ?: @"none"};
    [keychain removeItemForKey:[self repositoryURI]];
    
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:question options:(NSJSONWritingOptions)0 error:nil];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:URL];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:requestData];
    
    NSURLSessionDataTask *signOutTask = [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest]; // This will silently fail if there is an error
    [signOutTask resume];
}

- (BOOL)isSignedIn API_AVAILABLE(ios(11.0)) {
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    return [keychain stringForKey:self.repositoryURI] ? YES : NO;
}

- (NSString *)paymentSecret:(NSError **)error {
    __block NSString *paymentSecret = NULL;
    __block NSError *paymentError = NULL;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *paymentKeychainIdentifier = [NSString stringWithFormat:@"%@payment", [self repositoryURI]];
        
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
        [keychain setAccessibility:UICKeyChainStoreAccessibilityWhenPasscodeSetThisDeviceOnly
              authenticationPolicy:UICKeyChainStoreAuthenticationPolicyUserPresence];
        keychain.authenticationPrompt = NSLocalizedString(@"Authenticate to initiate purchase.", @"");
        
        paymentSecret = [keychain stringForKey:paymentKeychainIdentifier error:&paymentError];
        
        dispatch_semaphore_signal(sema);
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    if (paymentError) {
        NSLog(@"[Zebra] Payment error: %@", paymentError);
        if (error) *error = [paymentError copy];
    }
    return paymentSecret;
}

- (BOOL)supportsPaymentAPI {
    return self.paymentEndpointURL != NULL;
}

- (void)getUserInfo:(void (^)(ZBUserInfo *info, NSError *error))completion {
    if (!self.supportsPaymentAPI || ![self isSignedIn]) return;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self.paymentEndpointURL URLByAppendingPathComponent:@"user_info"]];
    
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    
    NSDictionary *requestJSON = @{@"token": [keychain stringForKey:[self repositoryURI]], @"udid": [ZBDevice UDID], @"device": [ZBDevice deviceModelID]};
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestJSON options:(NSJSONWritingOptions)0 error:nil];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Zebra/%@ (%@; iOS/%@)", PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:requestData];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpReponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [httpReponse statusCode];
        
        if (statusCode == 200 && !error) {
            NSError *parseError = NULL;
            ZBUserInfo *userInfo = [ZBUserInfo fromData:data error:&parseError];
            
            if (parseError || userInfo.error) {
                parseError ? completion(nil, parseError) : completion(nil, [NSError errorWithDomain:NSURLErrorDomain code:343 userInfo:@{NSLocalizedDescriptionKey: userInfo.error}]);
                return;
            }
            
            completion(userInfo, nil);
        }
        else if (error) {
            completion(nil, error);
        }
    }];
    
    [task resume];
}

- (void)getSourceInfo:(void (^)(ZBSourceInfo *info, NSError *error))completion {
    if (!self.paymentEndpointURL) return;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self.paymentEndpointURL URLByAppendingPathComponent:@"info"]];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:[NSString stringWithFormat:@"Zebra/%@ (%@; iOS/%@)", PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpReponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [httpReponse statusCode];
        
        if (statusCode == 200 && !error) {
            NSError *parseError = NULL;
            ZBSourceInfo *sourceInfo = [ZBSourceInfo fromData:data error:&parseError];
            
            if (parseError) {
                completion(nil, parseError);
                return;
            }
            
            completion(sourceInfo, nil);
        }
        else if (error) {
            completion(nil, error);
        }
    }];
    
    [task resume];
}

- (NSInteger)pinPriority {
    if (!self.remote) return 100;
    else if (_pinPriority == 0) return 500;
    else return _pinPriority;
}

//- (void)getPaymentEndpoint:(void (^)(NSURL *))completion {
//    if (checkedForPaymentEndpoint) completion(paymentEndpointURL);
//
//    [[NSURLSession sharedSession] dataTaskWithURL:[self.mainDirectoryURL URLByAppendingPathComponent:@"payment_endpoint"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        NSInteger httpStatus = [((NSHTTPURLResponse *)response) statusCode];
//        if (httpStatus == 200 && !error) {
//            NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            if (response) {
//                self->paymentEndpointURL = [NSURL URLWithString:response];
//            }
//        }
//        self->checkedForPaymentEndpoint = YES;
//        completion(self->paymentEndpointURL);
//    }];
//}

- (void)getFeaturedPackages:(void (^)(NSDictionary *))completion {
    if (self->featuredPackages) completion(featuredPackages);
    if (!self.supportsFeaturedPackages) completion(NULL);
    
    [[NSURLSession sharedSession] dataTaskWithURL:[self.mainDirectoryURL URLByAppendingPathComponent:@"sileo-featured.json"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger httpStatus = [((NSHTTPURLResponse *)response) statusCode];
        if (httpStatus == 200 && !error) {
            self->featuredPackages = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        }
        completion(self->featuredPackages);
    }];
}

- (NSDictionary <NSString *, NSNumber *> *)sections {
    return [[ZBSourceManager sharedInstance] sectionsForSource:self];
}

- (NSUInteger)numberOfPackages {
    return [[ZBSourceManager sharedInstance] numberOfPackagesInSource:self];
}

@end
