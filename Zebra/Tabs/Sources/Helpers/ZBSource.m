//
//  ZBSource.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBSource.h"
#import "ZBSourceManager.h"
#import "UICKeyChainStore.h"
#import <ZBAppDelegate.h>
#import <Database/ZBDatabaseManager.h>
#import <Database/ZBColumn.h>
#import <ZBDevice.h>

@implementation ZBSource

@synthesize sourceDescription;
@synthesize origin;
@synthesize version;
@synthesize suite;
@synthesize codename;
@synthesize architectures;
@synthesize repoID;
@synthesize paymentVendorURI;

const char *textColumn(sqlite3_stmt *statement, int column) {
    return (const char *)sqlite3_column_text(statement, column);
}

+ (ZBSource *)repoMatchingRepoID:(int)repoID {
    return [[ZBSourceManager sharedInstance] repos][@(repoID)];
}

+ (ZBSource *)localRepo:(int)repoID {
    ZBSource *local = [[ZBSource alloc] init];
    [local setOrigin:NSLocalizedString(@"Local Repository", @"")];
    [local setSourceDescription:NSLocalizedString(@"Locally installed packages", @"")];
    [local setRepoID:repoID];
    [local setBaseFilename:@"/var/lib/dpkg/status"];
    return local;
}

+ (ZBSource *)repoFromBaseURL:(NSString *)baseURL {
    return [[ZBDatabaseManager sharedInstance] repoFromBaseURL:baseURL];
}

+ (ZBSource *)sourceFromBaseFilename:(NSString *)baseFilename {
    return [[ZBDatabaseManager sharedInstance] repoFromBaseFilename:baseFilename];
}

+ (BOOL)exists:(NSString *)urlString {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    return [databaseManager repoIDFromBaseURL:urlString strict:NO] > 0;
}

- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement {
    const char *archiveTypeChars   = textColumn(statement, ZBSourceColumnArchiveType);
    const char *repositoryURIChars = textColumn(statement, ZBSourceColumnRepositoryURI);
    const char *distributionChars  = textColumn(statement, ZBSourceColumnDistribution);
    const char *componenetsChars   = textColumn(statement, ZBSourceColumnComponents);
    
    NSArray *components;
    if (componenetsChars != 0 && strcmp(componenetsChars, "") != 0) {
        components = [[NSString stringWithUTF8String:componenetsChars] componentsSeparatedByString:@" "];
    }
    
    self = [super initWithArchiveType:[NSString stringWithUTF8String:archiveTypeChars] repositoryURI:[NSString stringWithUTF8String:repositoryURIChars] distribution:[NSString stringWithUTF8String:distributionChars] components:components];
    
    if (self) {
        const char *descriptionChars   = textColumn(statement, ZBSourceColumnDescription);
        const char *originChars        = textColumn(statement, ZBSourceColumnOrigin);
        const char *labelChars         = textColumn(statement, ZBSourceColumnLabel);
        const char *versionChars       = textColumn(statement, ZBSourceColumnVersion);
        const char *suiteChars         = textColumn(statement, ZBSourceColumnSuite);
        const char *codenameChars      = textColumn(statement, ZBSourceColumnCodename);
        const char *architectureChars  = textColumn(statement, ZBSourceColumnArchitectures);
        const char *vendorChars        = textColumn(statement, ZBSourceColumnPaymentVendor);
        const char *baseFilenameChars  = textColumn(statement, ZBSourceColumnBaseFilename);

        [self setSourceDescription:descriptionChars != 0 ? [[NSString alloc] initWithUTF8String:descriptionChars] : NULL];
        [self setOrigin:originChars != 0 ? [[NSString alloc] initWithUTF8String:originChars] : NSLocalizedString(@"Unknown", @"")];
        [self setLabel:labelChars != 0 ? [[NSString alloc] initWithUTF8String:labelChars] : NSLocalizedString(@"Unknown", @"")];
        [self setVersion:versionChars != 0 ? [[NSString alloc] initWithUTF8String:versionChars] : NSLocalizedString(@"Unknown", @"")];
        [self setSuite:suiteChars != 0 ? [[NSString alloc] initWithUTF8String:suiteChars] : NSLocalizedString(@"Unknown", @"")];
        [self setCodename:codenameChars != 0 ? [[NSString alloc] initWithUTF8String:codenameChars] : NSLocalizedString(@"Unknown", @"")];
        
        if (vendorChars != 0) {
            NSString *vendor = [[[NSString alloc] initWithUTF8String:vendorChars] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [self setPaymentVendorURI:[[NSURL alloc] initWithString:vendor]];
        }
        
        if (architectureChars != 0) {
            NSArray *architectures = [[NSString stringWithUTF8String:architectureChars] componentsSeparatedByString:@" "];
            [self setArchitectures:architectures];
        }
        else {
            [self setArchitectures:@[@"all"]];
        }
        
        [self setBaseFilename:baseFilenameChars != 0 ? [[NSString alloc] initWithUTF8String:baseFilenameChars] : NULL];
        [self setRepoID:sqlite3_column_int(statement, ZBSourceColumnRepoID)];
        [self setIconURL:[self.mainDirectoryURL URLByAppendingPathComponent:@"CydiaIcon.png"]];
        
        // prevent constant network spam
        if (!self.checkedSupportFeaturedPackages) {
            // Check for featured string
            NSURL *checkingURL = [self.mainDirectoryURL URLByAppendingPathComponent:@"sileo-featured.json"];
            NSURLSession *session = [NSURLSession sharedSession];
            [[session dataTaskWithURL:checkingURL
                    completionHandler:^(NSData *data,
                                        NSURLResponse *response,
                                        NSError *error) {
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                        if (data != nil && (long)[httpResponse statusCode] != 404) {
                            [self setSupportsFeaturedPackages:YES];
                        }
                    }] resume];
            [self setCheckedSupportFeaturedPackages:YES];
        }
    }
    
    return self;
}

- (BOOL)canDelete {
    return ![[self baseFilename] isEqualToString:@"getzbra.com_repo_._"];
}

- (BOOL)isEqual:(ZBSource *)object {
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[ZBSource class]])
        return NO;
    
    return [[object baseFilename] isEqual:[self baseFilename]];
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ %@ %d", self.label, self.repositoryURI, self.repoID];
}

- (void)authenticate:(void (^)(BOOL success, NSError *_Nullable error))completion {
    if ([self isSignedIn]) {
        completion(YES, nil);
        return;
    }
    
    if ([self paymentVendorURL]) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:[[self paymentVendorURL] URLByAppendingPathComponent:@"authenticate"] resolvingAgainstBaseURL:YES];
        if (![components.scheme isEqualToString:@"https"]) {
            return;
        }
        
        NSMutableArray *queryItems = [components queryItems] ? [[components queryItems] mutableCopy] : [NSMutableArray new];
        NSURLQueryItem *udid = [NSURLQueryItem queryItemWithName:@"udid" value:[ZBDevice UDID]];
        NSURLQueryItem *model = [NSURLQueryItem queryItemWithName:@"model" value:[ZBDevice deviceModelID]];
        [queryItems addObject:udid];
        [queryItems addObject:model];
        [components setQueryItems:queryItems];
        
        NSURL *url = [components URL];
        if (@available(iOS 11.0, *)) {
            static SFAuthenticationSession *session;
            session = [[SFAuthenticationSession alloc] initWithURL:url callbackURLScheme:@"sileo" completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
                if (callbackURL) {
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
                        
                        completion(YES, NULL);
                    });
                }
                else {
                    if (error.domain != SFAuthenticationErrorDomain && error.code != SFAuthenticationErrorCanceledLogin) {
                        completion(NO, error);
                    }
                }
            }];
            
            [session start];
        }
        else {
//            [ZBDevice openURL:url delegate:nil];
        }
    }
}

- (BOOL)isSignedIn {
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    return [keychain stringForKey:self.repositoryURI];
}

- (NSString *)paymentSecret {
    __block NSString *paymentSecret;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *paymentKeychainIdentifier = [NSString stringWithFormat:@"%@payment", [self repositoryURI]];
        
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
        [keychain setAccessibility:UICKeyChainStoreAccessibilityWhenPasscodeSetThisDeviceOnly
              authenticationPolicy:UICKeyChainStoreAuthenticationPolicyUserPresence];
        keychain.authenticationPrompt = NSLocalizedString(@"Authenticate to initiate purchase.", @"");
        
        NSError *error;
        paymentSecret = [keychain stringForKey:paymentKeychainIdentifier error:&error];
        if (error) {
            NSLog(@"Error: %@", error);
        }
        
        dispatch_semaphore_signal(sema);
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return paymentSecret;
}

- (NSURL *)paymentVendorURL {
    if (paymentVendorURI) {
        return paymentVendorURI;
    }
    
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    paymentVendorURI = [databaseManager paymentVendorURLForRepo:self];
    return paymentVendorURI;
}

@end
