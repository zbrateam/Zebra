//
//  ZBAlternateIconController.h
//  Zebra
//
//  Created by midnightchips on 6/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewController.h"

@interface ZBAlternateIconController : ZBSettingsTableViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeButton;
+ (NSArray <NSDictionary *> *)icons;
+ (NSDictionary *)iconForName:(NSString *)name;
@end
