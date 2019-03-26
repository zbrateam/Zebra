//
//  ZBDependencyResolver.h
//  Zebra
//
//  Created by Wilson Styres on 3/26/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class ZBDatabaseManager;
@class ZBPackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBDependencyResolver : NSObject
@property (nonatomic, strong) ZBDatabaseManager *databaseManager;
@property (nonatomic) sqlite3 *database;
- (NSArray <NSArray <NSString *> *> *)dependenciesForPackage:(ZBPackage *)package;
@end

NS_ASSUME_NONNULL_END
