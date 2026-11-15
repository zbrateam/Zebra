//
//  SettingsTableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBTableViewController.h"
#import "ZBDevice.h"
#import "ZBRefreshViewController.h"
#import "ZBAppDelegate.h"
#import "ZBAlternateIconController.h"
@import SDWebImage;

@interface ZBSettingsTableViewController : ZBTableViewController <UINavigationControllerDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *headerView;
@property (strong, nonatomic) IBOutlet UIView *headerContainer;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@end
