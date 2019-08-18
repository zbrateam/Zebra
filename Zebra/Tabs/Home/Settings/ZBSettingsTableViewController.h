//
//  SettingsTableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBDevice.h"
#import <Extensions/UIColor+GlobalColors.h>
#import "ZBWebViewController.h"
#import "ZBRefreshViewController.h"
#import "ZBAppDelegate.h"
#import "ZBAlternateIconController.h"
#import "ZBChangeLogTableViewController.h"
#import "ZBCommunityReposTableViewController.h"
#import "ZBRepoBlacklistTableViewController.h"
@import SDWebImage;

@interface ZBSettingsTableViewController : UITableViewController <WKNavigationDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *headerView;
@property (weak, nonatomic) IBOutlet UIView *headerContainer;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property UIVisualEffectView *blurView;
@end
