//
//  MainSettingsTableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Tabs/Home/Settings/Table/ZBSettingsTableViewController.h>
#import <ZBDevice.h>
#import <ZBAppDelegate.h>
#import <Tabs/Home/Settings/App Icon/ZBAlternateIconController.h>

#import <SDWebImage/SDWebImage.h>
#import <UIKit/UIKit.h>

@interface ZBMainSettingsTableViewController : ZBSettingsTableViewController <UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *headerView;
@property (weak, nonatomic) IBOutlet UIView *headerContainer;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property UIVisualEffectView *blurView;
@end
