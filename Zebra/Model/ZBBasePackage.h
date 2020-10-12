//
//  ZBBasePackage.h
//  Zebra
//
//  Created by Wilson Styres on 10/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SQLite3;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBBasePackage : NSObject
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *version;
@property (nonatomic) NSString *packageDescription;
@property (nonatomic) NSString *section;
@property (nonatomic) NSString *authorName;
@property (nonatomic) NSDate   *lastSeen;
@property (nonatomic) NSString *uuid;
- (instancetype)initFromSQLiteStatement:(sqlite3_stmt *)statement;
- (NSObject *)loadPackage;
@end

NS_ASSUME_NONNULL_END
