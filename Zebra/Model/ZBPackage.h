//
//  ZBPackage.h
//  Zebra
//
//  Created by Wilson Styres on 2/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBBasePackage.h"

@import Foundation;
@import SQLite3;
@import UIKit;

@class UIImageView;
@class ZBSource;
@class ZBPurchaseInfo;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackage : ZBBasePackage <UIActivityItemSource>
@property (readonly) NSString *_Nullable authorEmail;
@property (readonly) NSString *_Nullable changelogNotes;
@property (readonly) NSString *_Nullable changelogTitle;
@property (readonly) NSArray *_Nullable conflicts;
@property NSString *_Nullable debPath;
@property (readonly) NSArray *_Nullable depends;
@property (readonly) NSURL *_Nullable depictionURL;
@property (readonly) NSUInteger downloadSize;
@property (readonly) BOOL essential;
@property (readonly) NSString *_Nullable filename;
@property (readonly) NSString * _Nullable highestCompatibleVersion;
@property (readonly) NSURL *_Nullable homepageURL;
@property (readonly) NSURL *_Nullable iconURL;
@property (readonly) BOOL isInstalled;
@property (readonly) BOOL isVersionInstalled;
@property (readonly) NSUInteger installedSize;
@property (readonly) NSString * _Nullable lowestCompatibleVersion;
@property (readonly) NSString *_Nullable maintainerName;
@property (readonly) NSString *_Nullable maintainerEmail;
@property (readonly) NSArray * _Nullable previewImageURLs;
@property (readonly) BOOL preferNative;
@property (readonly) NSString *priority;
@property (readonly) NSArray *_Nullable provides;
@property (readonly) NSArray *_Nullable replaces;
@property BOOL requiresAuthorization;
@property (readonly) NSString *_Nullable SHA256;
@property (readonly) ZBSource *source;
@property (readonly) NSArray *_Nullable tag;

// Old Properties
@property (nonatomic, strong) NSMutableArray <ZBPackage *> *dependencies;
@property (nonatomic, strong) NSMutableArray <ZBPackage *> *dependencyOf;
@property (nonatomic, strong) NSMutableArray <NSString *> *issues;
@property (nonatomic, strong) ZBPackage * _Nullable removedBy;
@property BOOL ignoreDependencies;

+ (NSArray *)filesInstalledBy:(NSString *)packageID;
+ (BOOL)respringRequiredFor:(NSString *)packageID;
+ (NSString *)applicationBundlePathForIdentifier:(NSString *)packageID;
- (id)initFromDeb:(NSString *)path;
- (NSComparisonResult)compare:(id _Nullable)object;
- (BOOL)sameAs:(ZBPackage * _Nonnull)package;
- (BOOL)sameAsStricted:(ZBPackage * _Nonnull)package;
- (BOOL)isPaid;
- (NSString * _Nullable)getField:(NSString * _Nonnull)field;
- (BOOL)canReinstall;
- (NSArray <ZBPackage *> *)allVersions;
- (NSArray <ZBPackage *> *)otherVersions;
- (NSArray <ZBPackage *> *)lesserVersions;
- (NSArray <ZBPackage *> *)greaterVersions;
- (BOOL)areUpdatesIgnored;
- (void)setIgnoreUpdates:(BOOL)ignore;
- (NSString * _Nullable)downloadSizeString;
- (NSString * _Nullable)installedSizeString;
- (nonnull NSDate *)installedDate;
- (NSString * _Nullable)installedVersion;
- (void)addDependency:(ZBPackage * _Nonnull)package;
- (void)addDependencyOf:(ZBPackage * _Nonnull)package;
- (void)addIssue:(NSString * _Nonnull)issue;
- (BOOL)hasIssues;
- (BOOL)isEssentialOrRequired;
- (NSArray * _Nullable)possibleActions;
- (NSArray * _Nullable)possibleExtraActions;
- (void)setIconImageForImageView:(UIImageView * _Nonnull)imageView;
- (NSArray * _Nonnull)information;
- (BOOL)hasChangelog;

#pragma mark - Modern Payment API
- (BOOL)mightRequirePayment;
- (void)purchaseInfo:(void (^_Nonnull)(ZBPurchaseInfo * _Nullable info))completion;
- (void)purchase:(void (^_Nonnull)(BOOL success, NSError *_Nullable error))completion;
@end

NS_ASSUME_NONNULL_END
