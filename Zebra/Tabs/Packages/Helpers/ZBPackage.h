//
//  ZBPackage.h
//  Zebra
//
//  Created by Wilson Styres on 2/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class ZBRepo;

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
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) ZBRepo *repo;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *iconPath;
@property (nonatomic, strong) NSString *origBundleID;
@property (nonatomic, strong) NSDate *lastSeenDate;
@property BOOL sileoDownload;

+ (NSArray *)filesInstalled:(NSString *)packageID;
+ (BOOL)containsTweak:(NSString *)packageID;
+ (BOOL)containsApp:(NSString *)packageID;
+ (NSString *)pathForApplication:(NSString *)packageID;
- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement;
- (NSComparisonResult)compare:(id)object;
- (BOOL)sameAs:(ZBPackage *)package;
- (BOOL)isPaid;
- (NSString *)getField:(NSString *)field;
- (BOOL)isInstalled:(BOOL)strict;
- (BOOL)isReinstallable;
- (NSArray <ZBPackage *> *)otherVersions;
- (NSUInteger)possibleActions;
- (BOOL)ignoreUpdates;
- (void)setIgnoreUpdates:(BOOL)ignore;
- (NSString *)size;
- (NSString *)installedSize;
- (int)numericSize;
- (int)numericInstalledSize;
- (ZBPackage *)installableCandidate;
- (NSDate *)installedDate;
- (NSString *)installedVersion;
@end

NS_ASSUME_NONNULL_END
