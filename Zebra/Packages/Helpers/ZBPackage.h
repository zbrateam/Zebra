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
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *section;
@property (nonatomic, strong) NSString *sectionImageName;
@property (nonatomic, strong) NSURL *depictionURL;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSArray *dependsOn;
@property (nonatomic, strong) NSArray *conflictsWith;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) ZBRepo *repo;
@property (nonatomic, strong) NSString *filename;
@property BOOL sileoDownload;

+ (NSArray *)filesInstalled:(NSString *)packageID;
+ (BOOL)containsTweak:(NSString *)packageID;
+ (BOOL)containsApp:(NSString *)packageID;
+ (NSString *)pathForApplication:(NSString *)packageID;
- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement;
- (NSComparisonResult)compare:(id)object;
- (BOOL)isPaid;
- (NSString *)getField:(NSString *)field;
- (BOOL)hasNoRepo;
- (BOOL)isLocal;
- (BOOL)isStrictlyInstalled;
- (BOOL)isInstalled;
- (BOOL)isReinstallable;
- (NSMutableArray <ZBPackage *> *)otherVersions;
- (NSUInteger)possibleActions;
@end

NS_ASSUME_NONNULL_END
