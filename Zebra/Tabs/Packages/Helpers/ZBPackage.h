//
//  ZBPackage.h
//  Zebra
//
//  Created by Wilson Styres on 2/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

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
@property (nonatomic, strong) NSString *sectionImageName;
@property (nonatomic, strong) NSURL *depictionURL;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSArray <NSString *> *dependsOn;
@property (nonatomic, strong) NSArray <NSString *> *conflictsWith;
@property (nonatomic, strong) NSArray <NSString *> *provides;
@property (nonatomic, strong) NSArray <NSString *> *replaces;
@property (nonatomic, strong) NSString *authorName;
@property (nonatomic, strong) NSString *authorEmail;
@property (nonatomic, strong) ZBSource *repo;
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
@property int installedSize;
@property int downloadSize;
@property BOOL sileoDownload;
@property BOOL essential;
@property BOOL ignoreDependencies;

+ (NSArray *)filesInstalledBy:(NSString *)packageID;
+ (BOOL)respringRequiredFor:(NSString *)packageID;
+ (NSString *)applicationBundlePathForIdentifier:(NSString *)packageID;
- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement;
- (NSComparisonResult)compare:(id)object;
- (BOOL)sameAs:(ZBPackage *)package;
- (BOOL)sameAsStricted:(ZBPackage *)package;
- (BOOL)isPaid;
- (void)purchaseInfo:(void (^)(ZBPurchaseInfo *info))completion;
- (NSString *)getField:(NSString *)field;
- (BOOL)isInstalled:(BOOL)strict;
- (BOOL)isReinstallable;
- (NSArray <ZBPackage *> *)otherVersions;
- (NSArray <ZBPackage *> *)lesserVersions;
- (NSArray <ZBPackage *> *)greaterVersions;
- (NSUInteger)possibleActions;
- (BOOL)ignoreUpdates;
- (void)setIgnoreUpdates:(BOOL)ignore;
- (NSString *)downloadSizeString;
- (NSString *)installedSizeString;
- (ZBPackage *)installableCandidate;
- (ZBPackage *)removeableCandidate;
- (NSDate *)installedDate;
- (NSString *)installedVersion;
- (void)addDependency:(ZBPackage *)package;
- (void)addDependencyOf:(ZBPackage *)package;
- (void)addIssue:(NSString *)issue;
- (BOOL)hasIssues;
- (BOOL)isEssentialOrRequired;
- (void)_setPossibleActions:(NSUInteger)actions;
@end

NS_ASSUME_NONNULL_END
