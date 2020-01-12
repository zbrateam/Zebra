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
@property NSArray<NSString *> *footerText;
@property NSArray<NSString *> *options;
@property NSInteger selectedRow;
@property void (^settingChanged)(NSInteger newValue);
@end
