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

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageListTableViewController : UITableViewController
@property (nonatomic, strong) ZBRepo *repo;
@property (nonatomic, strong) NSString *section;
- (void)refreshTable;
@end

NS_ASSUME_NONNULL_END
