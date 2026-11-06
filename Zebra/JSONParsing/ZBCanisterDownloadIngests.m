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
#import "ZBJSONObject.h"

@interface ZBCanisterReference : ZBJSONObject
@property (nonatomic, copy, nullable) NSString *privacyPolicy;
@property (nonatomic, copy, nullable) NSString *privacyUpdated;
@end

@interface ZBCanisterInfoData : ZBJSONObject
@property (nonatomic, strong, nullable) ZBCanisterReference *reference;
@end

@interface ZBCanisterInfo : ZBJSONObject
@property (nonatomic, strong, nullable) ZBCanisterInfoData *data;
@end

@implementation ZBCanisterReference

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"privacy_policy": ZBJSONString(@"privacyPolicy"),
            @"privacy_updated": ZBJSONString(@"privacyUpdated")
        };
    }
    return properties;
}

@end

@implementation ZBCanisterInfoData

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"reference": ZBJSONObject(@"reference", [ZBCanisterReference class])
        };
    }
    return properties;
}

@end

@implementation ZBCanisterInfo

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary <NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"data": ZBJSONObject(@"data", [ZBCanisterInfoData class])
        };
    }
    return properties;
}

@end

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
        ZBCanisterReference *info = [ZBCanisterInfo fromData:data error:nil].data.reference;
        if (!info.privacyPolicy || !info.privacyUpdated) {
            completion(nil);
            return;
        }
        NSURL *privacyPolicyURL = [[NSURL alloc] initWithString:info.privacyPolicy];
        NSString *changedDate = info.privacyUpdated;
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
