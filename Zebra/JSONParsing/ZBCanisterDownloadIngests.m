//
//  ZBCanisterDownloadIngests.m
//  Zebra
//
//  Created by Amy While on 10/06/2023.
//  Copyright © 2023 Zebra Team. All rights reserved.
//

#import "ZBCanisterDownloadIngests.h"
#import "NSURLSession+Zebra.h"

@implementation CanisterPackage

-(instancetype)initWithPackage:(ZBPackage *_Nonnull)package {
    if (self = [super init]) {
        self.package_id = package.identifier;
        self.package_version = package.version;
        if (package.authorEmail && package.authorName) {
            self.package_author = [NSString stringWithFormat:@"%@ <%@>", package.authorName, package.authorEmail];
        } else if (package.authorEmail) {
            self.package_author = package.authorEmail;
        } else if (package.authorName) {
            self.package_author = package.authorName;
        } else {
            self.package_author = @"Unknown";
        }
        self.package_maintainer = self.package_author;
        ZBSource *source = package.source;
        if (source) {
            self.repostiory_uri = [source repositoryURI];
        } else {
            self.repostiory_uri = NULL;
        }
    }
    return self;
}

-(NSDictionary *)dictionary {
    return @{
        @"package_id": self.package_id ?: [NSNull null],
        @"package_version": self.package_version ?: [NSNull null],
        @"package_author": self.package_author ?: [NSNull null],
        @"package_maintainer": self.package_maintainer ?: [NSNull null],
        @"repository_uri": self.repostiory_uri ?: [NSNull null]
    };
}

@end

@implementation CanisterIngest

+(void)ingestPackages:(NSArray<ZBPackage *>*)packages {
    if (![[NSUserDefaults standardUserDefaults] integerForKey:@"CanisterIngest"]) {
        return;
    }
    NSMutableArray<NSDictionary *> *canisterPackages = [NSMutableArray new];
    for (ZBPackage *package in packages) {
        [canisterPackages addObject:[[CanisterPackage alloc] initWithPackage:package].dictionary];
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
    [[[NSURLSession zbra_standardSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    }] resume];
}

@end
