//
//  ZBAlternateIconController.h
//  Zebra
//
//  Created by midnightchips on 6/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPreferencesViewController.h"

@interface ZBAlternateIconController : ZBPreferencesViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeButton;
+ (NSArray <NSDictionary *> *)icons;
+ (NSDictionary *)iconForName:(NSString *)name;
@end
