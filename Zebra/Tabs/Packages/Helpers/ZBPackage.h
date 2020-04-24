//
//  ZBPackage.h
//  Zebra
//
//  Created by Wilson Styres on 2/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class UIImageView;
@class ZBSource;
@class ZBPurchaseInfo;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackage : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *shortDescription;
@property (nonatomic, strong) NSString *longDescription;
@property (nonatomic, strong) NSString *section;
@property (nonatomic, strong) NSURL *depictionURL;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSArray <NSString *> *dependsOn;
@property (nonatomic, strong) NSArray <NSString *> *conflictsWith;
@property (nonatomic, strong) NSArray <NSString *> *provides;
@property (nonatomic, strong) NSArray <NSString *> *replaces;
@property (nonatomic, strong) NSString *authorName;
@property (nonatomic, strong) NSString *authorEmail;
@property (nonatomic, strong) ZBSource *source;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *debPath;
@property (nonatomic, strong) NSString *iconPath;
@property (nonatomic, strong) NSString *origBundleID;
@property (nonatomic, strong) NSDate *lastSeenDate;
@property (nonatomic, strong) NSMutableArray <ZBPackage *> *dependencies;
@property (nonatomic, strong) NSMutableArray <ZBPackage *> *dependencyOf;
@property (nonatomic, strong) NSMutableArray <NSString *> *issues;
@property (nonatomic, strong) ZBPackage * _Nullable removedBy;
@property (nonatomic, strong) NSString *priority;
@property (nonatomic, strong) NSString *SHA256;
@property int installedSize;
@property int downloadSize;
@property BOOL requiresAuthorization;
@property BOOL essential;
@property BOOL ignoreDependencies;

+ (NSArray *)filesInstalledBy:(NSString *)packageID;
+ (BOOL)respringRequiredFor:(NSString *)packageID;
+ (NSString * _Nullable)applicationBundlePathForIdentifier:(NSString *)packageID;
- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement;
- (id)initFromDeb:(NSString *)path;
- (NSComparisonResult)compare:(id)object;
- (BOOL)sameAs:(ZBPackage *)package;
- (BOOL)sameAsStricted:(ZBPackage *)package;
- (BOOL)isPaid;
- (NSString * _Nullable)getField:(NSString *)field;
- (BOOL)isInstalled:(BOOL)strict;
- (BOOL)isReinstallable;
- (NSArray <ZBPackage *> *)otherVersions;
- (NSArray <ZBPackage *> *)lesserVersions;
- (NSArray <ZBPackage *> *)greaterVersions;
- (BOOL)ignoreUpdates;
- (void)setIgnoreUpdates:(BOOL)ignore;
- (NSString *)downloadSizeString;
- (NSString *)installedSizeString;
- (ZBPackage * _Nullable)installableCandidate;
- (ZBPackage * _Nullable)removeableCandidate;
- (NSDate *)installedDate;
- (NSString * _Nullable)installedVersion;
- (void)addDependency:(ZBPackage *)package;
- (void)addDependencyOf:(ZBPackage *)package;
- (void)addIssue:(NSString *)issue;
- (BOOL)hasIssues;
- (BOOL)isEssentialOrRequired;
- (NSArray * _Nullable)possibleActions;
- (void)setIconImageForImageView:(UIImageView *)imageView;

#pragma mark - Modern Payment API
- (BOOL)mightRequirePayment API_AVAILABLE(ios(11.0));
- (void)purchaseInfo:(void (^)(ZBPurchaseInfo *info))completion API_AVAILABLE(ios(11.0));
- (void)purchase:(void (^)(BOOL success, NSError *_Nullable error))completion API_AVAILABLE(ios(11.0));
@end

NS_ASSUME_NONNULL_END
