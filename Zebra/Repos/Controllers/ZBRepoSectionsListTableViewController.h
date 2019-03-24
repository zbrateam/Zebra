//
//  ZBRepoSectionsListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZBRepo;
@class ZBDatabaseManager;

NS_ASSUME_NONNULL_BEGIN

@interface ZBRepoSectionsListTableViewController : UITableViewController
@property (nonatomic, strong) ZBRepo *repo;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) ZBDatabaseManager *databaseManager;
@end

NS_ASSUME_NONNULL_END
