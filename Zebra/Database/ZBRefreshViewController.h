//
//  ZBRefreshViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ZBDatabaseDelegate.h>
#import "UIColor+GlobalColors.h"

@interface ZBRefreshViewController : UIViewController <ZBDatabaseDelegate>
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, retain) NSArray <NSURL *> *repoURLs;
@property (nonatomic) BOOL dropTables;
- (id)init;
- (id)initWithMessages:(NSArray *)messages;
- (id)initWithDropTables:(BOOL)dropTables;
- (id)initWithRepoURLs:(NSArray *)repoURLs;
- (id)initWithMessages:(NSArray *)messages dropTables:(BOOL)dropTables;
- (id)initWithMessages:(NSArray *)messages repoURLs:(NSArray *)repoURLs;
- (id)initWithDropTables:(BOOL)dropTables repoURLs:(NSArray *)repoURLs;
- (id)initWithMessages:(NSArray *)messages dropTables:(BOOL)dropTables repoURLs:(NSArray *)repoURLs;
@end

