//
//  TableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/18/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBPackage.h"
#import "ZBPackageTableViewCell.h"
#import "UIColor+GlobalColors.h"
#import "ZBDatabaseManager.h"
#import "ZBPackageDepictionViewController.h"
#import "ZBPackageActionsManager.h"

@interface ZBWishListTableViewController : UITableViewController
@property NSMutableArray *wishedPackages;
@property NSMutableArray *wishedPackageIdentifiers;
@end
