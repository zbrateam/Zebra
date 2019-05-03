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
@property (nonatomic, strong) ZBDatabaseManager *databaseManager;
@property (nonatomic, strong) ZBRepo *repo;
@property (nonatomic, strong) NSDictionary *sectionReadout;
@property (nonatomic, strong) NSArray *sectionNames;
@end

NS_ASSUME_NONNULL_END
