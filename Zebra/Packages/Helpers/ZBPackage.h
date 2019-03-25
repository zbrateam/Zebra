//
//  ZBPackage.h
//  Zebra
//
//  Created by Wilson Styres on 2/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackage : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *section;
@property (nonatomic, strong) NSURL *depictionURL;
@property (nonatomic) BOOL installed;
@property (nonatomic) BOOL remote;

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name version:(NSString *)version description:(NSString *)desc section:(NSString *)section depictionURL:(NSString *)url installed:(BOOL)installed remote:(BOOL)remote;
- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement;
@end

NS_ASSUME_NONNULL_END
