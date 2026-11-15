//
//  ZBAlternateIconController.h
//  Zebra
//
//  Created by midnightchips on 6/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBTableViewController.h"

@interface ZBAlternateIconController : ZBTableViewController
@property (strong, nonatomic) IBOutlet UIBarButtonItem *closeButton;
+ (NSArray <NSDictionary *> *)icons;
+ (NSDictionary *)iconForName:(NSString *)name;
@end
