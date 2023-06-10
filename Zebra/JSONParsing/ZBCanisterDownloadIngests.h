//
//  ZBCanisterDownloadIngests.h
//  Zebra
//
//  Created by Amy While on 10/06/2023.
//  Copyright © 2023 Zebra Team. All rights reserved.
//

#ifndef ZBCanisterDownloadIngests_h
#define ZBCanisterDownloadIngests_h

#import <Foundation/Foundation.h>
#import "ZBPackage.h"
#import "ZBSource.h"

@interface CanisterPackage: NSObject
-(instancetype _Nonnull)initWithPackage:(ZBPackage *_Nonnull)package;
-(NSDictionary *_Nonnull)dictionary;
@property (nonatomic, nullable, strong) NSString *package_id;
@property (nonatomic, nullable, strong) NSString *package_version;
@property (nonatomic, nullable, strong) NSString *package_author;
@property (nonatomic, nullable, strong) NSString *package_maintainer;
@property (nonatomic, nullable, strong) NSString *repostiory_uri;
@end

@interface CanisterIngest: NSObject
+(void)ingestPackages:(NSArray<ZBPackage *>*_Nonnull)packages;
@end

#endif /* ZBCanisterDownloadIngests_h */
