//
//  ZBPackageManager.h
//  Zebra
//
//  Created by Wilson Styres on 10/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import Foundation;

@class ZBPackage;
@class ZBBasePackage;
@class ZBPackageFilter;
@class ZBSource;
@class ZBBaseSource;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageManager : NSObject
@property (readonly) NSDictionary <NSString *,NSString *> *installedPackagesList;
+ (instancetype)sharedInstance;
- (BOOL)isPackageInstalled:(ZBBasePackage *)package;
- (BOOL)isPackageInstalled:(ZBBasePackage *)package checkVersion:(BOOL)checkVersion;
- (void)importPackagesFromSource:(ZBBaseSource *)source;
- (void)packagesMatchingFilter:(ZBPackageFilter *)filter completion:(void (^)(NSArray <ZBPackage *> *packages))completion;
- (NSArray <ZBPackage *> *)latestPackages:(NSUInteger)limit;

- (ZBPackage *_Nullable)installedInstanceOfPackage:(ZBPackage *)package;
- (ZBPackage *_Nullable)instanceOfPackage:(ZBPackage *)package withVersion:(NSString *)version;
- (NSArray <ZBPackage *> *)allInstancesOfPackage:(ZBPackage *)package;
- (ZBPackage *_Nullable)packageWithUniqueIdentifier:(NSString *)uuid;
- (NSArray <ZBPackage *> *)packagesByAuthorWithName:(NSString *)name email:(NSString *_Nullable)email;

- (BOOL)canReinstallPackage:(ZBPackage *)package;

- (void)searchForPackagesByName:(NSString *)name completion:(void (^)(NSArray <ZBPackage *> *packages))completion;
- (void)searchForPackagesByDescription:(NSString *)description completion:(void (^)(NSArray <ZBPackage *> *packages))completion;
- (void)searchForPackagesByAuthorWithName:(NSString *)name completion:(void (^)(NSArray <ZBPackage *> *packages))completion;

- (NSString *)installedVersionOfPackage:(ZBPackage *)package;

- (NSArray <ZBPackage *> *)filterPackages:(NSArray <ZBPackage *> *)packages withFilter:(ZBPackageFilter *)filter;

@end

NS_ASSUME_NONNULL_END
