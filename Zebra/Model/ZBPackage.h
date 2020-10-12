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

@interface ZBPackage : ZBBasePackage <UIActivityItemSource>
@property (nonatomic, strong) NSURL * _Nullable depictionURL;
@property (nonatomic, strong) NSArray <NSString *> * _Nullable tag;
@property (nonatomic, strong) NSArray <NSString *> *_Nullable depends;
@property (nonatomic, strong) NSArray <NSString *> * _Nullable conflicts;
@property (nonatomic, strong) NSArray <NSString *> * _Nullable provides;
@property (nonatomic, strong) NSArray <NSString *> *_Nullable replaces;
@property (nonatomic, strong) ZBSource * _Nullable source;
@property (nonatomic, strong) NSString * _Nullable filename;
@property (nonatomic, strong) NSString * _Nullable debPath;
@property (nonatomic, strong) NSURL * _Nullable iconURL;
@property (nonatomic, strong) NSString * _Nullable origBundleID;
@property (nonatomic, strong) NSMutableArray <ZBPackage *> * _Nonnull dependencies;
@property (nonatomic, strong) NSMutableArray <ZBPackage *> * _Nonnull dependencyOf;
@property (nonatomic, strong) NSMutableArray <NSString *> * _Nonnull issues;
@property (nonatomic, strong) ZBPackage * _Nullable removedBy;
@property (nonatomic, strong) NSString * _Nullable priority;
@property (nonatomic, strong) NSString * _Nullable SHA256;
@property (nonatomic, strong) NSURL * _Nullable headerURL;
@property (nonatomic, strong) NSString * _Nullable changelogTitle;
@property (nonatomic, strong) NSString * _Nullable changelogNotes;
@property (nonatomic, strong) NSURL * _Nullable homepageURL;
@property (nonatomic, strong) NSArray * _Nullable previewImageURLs;
@property (nonatomic, strong) NSString * _Nullable maintainerName;
@property (nonatomic, strong) NSString * _Nullable maintainerEmail;
@property (nonatomic, strong) NSString * _Nullable authorEmail;
@property int installedSize;
@property int downloadSize;
@property BOOL requiresAuthorization;
@property BOOL essential;
@property BOOL ignoreDependencies;
@property BOOL preferNative;
@property (nonatomic, readonly) NSString * _Nullable lowestCompatibleVersion;
@property (nonatomic, readonly) NSString * _Nullable highestCompatibleVersion;
@property int16_t role;

+ (NSArray * _Nonnull)filesInstalledBy:(NSString * _Nonnull)packageID;
+ (BOOL)respringRequiredFor:(NSString * _Nonnull)packageID;
+ (NSString * _Nullable)applicationBundlePathForIdentifier:(NSString * _Nonnull)packageID;
- (id _Nonnull)initFromDeb:(NSString * _Nullable)path;
- (NSComparisonResult)compare:(id _Nullable)object;
- (BOOL)sameAs:(ZBPackage * _Nonnull)package;
- (BOOL)sameAsStricted:(ZBPackage * _Nonnull)package;
- (BOOL)isPaid;
- (NSString * _Nullable)getField:(NSString * _Nonnull)field;
- (BOOL)isInstalled:(BOOL)strict;
- (BOOL)isReinstallable;
- (NSMutableArray <ZBPackage *> * _Nullable)allVersions;
- (NSMutableArray <ZBPackage *> * _Nullable)otherVersions;
- (NSMutableArray <ZBPackage *> * _Nullable)lesserVersions;
- (NSMutableArray <ZBPackage *> * _Nullable)greaterVersions;
- (BOOL)ignoreUpdates;
- (void)setIgnoreUpdates:(BOOL)ignore;
- (NSString * _Nullable)downloadSizeString;
- (NSString * _Nullable)installedSizeString;
- (ZBPackage * _Nullable)installableCandidate;
- (ZBPackage * _Nullable)removeableCandidate;
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
