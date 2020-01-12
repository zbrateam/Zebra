//
//  ZBSettingsGraphicsTintTableViewController.h
//  Zebra
//
//  Created by Louis on 02/11/2019.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBDevice.h"
#import <Extensions/UIColor+GlobalColors.h>

@interface ZBSettingsOptionsTableViewController : UITableViewController
@property NSString *settingTitle;
@property NSArray<NSString *> *settingFooter;
@property NSArray<NSString *> *settingOptions;
@property NSInteger settingSelectedRow;
@property void (^settingChanged)(NSInteger newValue);
@end
