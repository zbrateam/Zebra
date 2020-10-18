//
//  ZBPackageManager.h
//  Zebra
//
//  Created by Wilson Styres on 10/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import Foundation;

@class ZBBasePackage;
@class ZBSource;
@class ZBBaseSource;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageManager : NSObject
@property (readonly) NSDictionary <NSString *,NSString *> *installedPackagesList;
+ (instancetype)sharedInstance;
- (BOOL)isPackageInstalled:(ZBBasePackage *)package;
- (BOOL)isPackageInstalled:(ZBBasePackage *)package checkVersion:(BOOL)checkVersion;
- (void)importPackagesFromSource:(ZBBaseSource *)source;
- (NSArray <ZBBasePackage *> *)packagesFromSource:(ZBSource *)source;
@end

NS_ASSUME_NONNULL_END
