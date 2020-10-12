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

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageManager : NSObject
- (void)importPackagesFromFile:(NSString *)path toSource:(ZBSource *)source;
- (NSArray <ZBBasePackage *> *)packagesFromSource:(ZBSource *)source;
@end

NS_ASSUME_NONNULL_END
