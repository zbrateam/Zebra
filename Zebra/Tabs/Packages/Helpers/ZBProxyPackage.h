//
//  ZBProxyPackage.h
//  Zebra
//
//  Created by Wilson Styres on 2/23/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@class UIImageView;
@class ZBPackage;

#import <Foundation/Foundation.h>
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBProxyPackage : NSObject

//Identifying properties
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *version;
@property (nonatomic) int repoID;

//Extra properties for display
@property (nonatomic) NSString *author;
@property (nonatomic) NSURL *iconURL;
@property (nonatomic) NSString *section;

@property (nonatomic) ZBPackage *package;
- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement;
- (BOOL)isInstalled;
- (ZBPackage *)loadPackage;
- (void)setIconImageForImageView:(UIImageView *)imageView;
@end

NS_ASSUME_NONNULL_END
