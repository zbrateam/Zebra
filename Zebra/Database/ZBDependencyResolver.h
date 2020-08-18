//
//  ZBDependencyResolver.h
//  Zebra
//
//  Created by Wilson Styres on 3/26/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBDatabaseManager;
@class ZBPackage;
@class ZBQueue;

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface ZBDependencyResolver : NSObject {
    ZBDatabaseManager *databaseManager;
    ZBPackage *package;
    ZBQueue *queue;
}
+ (NSArray *)separateVersionComparison:(NSString *)dependency;
+ (BOOL)doesPackage:(ZBPackage *)package satisfyComparison:(nonnull NSString *)comparison ofVersion:(nonnull NSString *)version;
+ (BOOL)doesVersion:(NSString *)candidate satisfyComparison:(NSString *)comparison ofVersion:(NSString *)version;
+ (NSComparisonResult)compareVersion:(NSString *)firstVersion toVersion:(NSString *)secondVersion;
- (id)initWithPackage:(ZBPackage *)package;
- (BOOL)immediateResolution;
@end

NS_ASSUME_NONNULL_END
