//
//  ZBCanisterDownloadIngests.m
//  Zebra
//
//  Created by Amy While on 10/06/2023.
//  Copyright © 2023 Zebra Team. All rights reserved.
//

#import "ZBCanisterDownloadIngests.h"
#import "NSURLSession+Zebra.h"
#import "ZBSettings.h"

@implementation ZBCanisterPackage

- (instancetype)initWithPackage:(ZBPackage *)package {
    self = [super init];
    if (self) {
        self.packageID = package.identifier;
        self.packageVersion = package.version;

        if (package.authorEmail && package.authorName) {
            self.packageAuthor = [NSString stringWithFormat:@"%@ <%@>", package.authorName, package.authorEmail];
        } else {
            self.packageAuthor = package.authorEmail ?: package.authorName ?: @"Unknown";
        }

        self.packageMaintainer = self.packageAuthor;
        self.repositoryURL = package.source.repositoryURI;
    }
    return self;
}

- (NSDictionary *)dictionary {
    return @{
        @"package_id": self.packageID ?: [NSNull null],
        @"package_version": self.packageVersion ?: [NSNull null],
        @"package_author": self.packageAuthor ?: [NSNull null],
        @"package_maintainer": self.packageMaintainer ?: [NSNull null],
        @"repository_uri": self.repositoryURL ?: [NSNull null]
    };
}

@end

@implementation ZBCanisterIngest

+ (void)checkCanisterPrivacyPolicyWithCompletion:(void (^)(NSURL  * _Nullable))completion {
    NSURL *canisterURL = [[NSURL alloc] initWithString:@"https://api.canister.me/v2/"];
    [[[NSURLSession zbra_standardSession] dataTaskWithURL:canisterURL completionHandler:^(NSData * _Nullable data, __unused NSURLResponse * _Nullable response, __unused NSError * _Nullable error) {
        if (!data) {
            completion(nil);
            return;
        }
        NSError *serializationError;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&serializationError];
        if (serializationError || ![dict isKindOfClass:[NSDictionary class]]) {
            completion(nil);
            return;
        }
        NSDictionary *dataDict = dict[@"data"];
        if (![dataDict isKindOfClass:[NSDictionary class]]) {
            completion(nil);
            return;
        }
        NSDictionary *info = dataDict[@"reference"];
        if (![info isKindOfClass:[NSDictionary class]]) {
            completion(nil);
            return;
        }
        NSString *privacyPolicy = info[@"privacy_policy"];
        if (![privacyPolicy isKindOfClass:[NSString class]]) {
            completion(nil);
            return;
        }
        NSURL *privacyPolicyURL = [[NSURL alloc] initWithString:privacyPolicy];
        NSString *changedDate = info[@"privacy_updated"];
        if (![changedDate isKindOfClass:[NSString class]]) {
            completion(nil);
            return;
        }
        NSString *pastDate = [ZBSettings canisterUpdateDate];

        BOOL needsUpdate = [ZBSettings sendCanisterIngest] == ZBSendCanisterIngestUnspecified || ![changedDate isEqualToString:pastDate];
        if (needsUpdate) {
            [ZBSettings setCanisterUpdateDate:changedDate];
            completion(privacyPolicyURL);
        } else {
            completion(nil);
        }
    }] resume];
}

+ (void)ingestPackages:(NSArray<ZBPackage *>*)packages {
    if ([ZBSettings sendCanisterIngest] != ZBSendCanisterIngestYes) {
        return;
    }
    NSMutableArray<NSDictionary *> *canisterPackages = [NSMutableArray new];
    for (ZBPackage *package in packages) {
        [canisterPackages addObject:[[ZBCanisterPackage alloc] initWithPackage:package].dictionary];
    }
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:canisterPackages options:NSJSONWritingFragmentsAllowed error:&error];
    if (error) {
        NSLog(@"[Zebra] Error Converting Packages to JSON: %@", error.localizedDescription);
        return;
    }
    NSLog(@"[Zebra] Got HTTP Data: %@", data);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"https://api.canister.me/v2/jailbreak/download/ingest"] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:5.0];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [[[NSURLSession zbra_standardSession] dataTaskWithRequest:request] resume];
}

@end
