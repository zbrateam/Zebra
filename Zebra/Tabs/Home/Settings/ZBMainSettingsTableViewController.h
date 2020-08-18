//
//  MainSettingsTableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewController.h"
#import <ZBDevice.h>
#import <Database/ZBRefreshViewController.h>
#import <ZBAppDelegate.h>
#import "App Icon/ZBAlternateIconController.h"

@import SDWebImage;
@import UIKit;

@interface ZBMainSettingsTableViewController : ZBSettingsTableViewController <UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *headerView;
@property (weak, nonatomic) IBOutlet UIView *headerContainer;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property UIVisualEffectView *blurView;
@end
