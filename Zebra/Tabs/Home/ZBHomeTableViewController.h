//
//  ZBHomeTableViewController.h
//  Zebra
//
//  Created by midnightchips on 7/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIColor+GlobalColors.h"
#import "ZBDevice.h"
#import "ZBStoresListTableViewController.h"
#import "ZBSettingsTableViewController.h"
#import "ZBWishListTableViewController.h"
#import "ZBWebViewController.h"
@interface ZBHomeTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *darkModeButton;

@end
