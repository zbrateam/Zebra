//
//  ZBPackageListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBPackageDepictionViewController.h"

@class ZBRepo;
@class ZBDatabaseManager;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageListTableViewController : UITableViewController <UIViewControllerPreviewingDelegate>
@property (nonatomic, strong) ZBDatabaseManager *databaseManager;
@property (nonatomic, strong) ZBRepo *repo;
@property (nonatomic, strong) NSString *section;
- (void)refreshTable;
- (void)setDestinationVC:(NSIndexPath *)indexPath destination:(ZBPackageDepictionViewController *)destination;
@end

NS_ASSUME_NONNULL_END
