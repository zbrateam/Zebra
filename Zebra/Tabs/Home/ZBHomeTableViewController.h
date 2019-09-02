//
//  ZBHomeTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 8/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBPackage;

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBHomeTableViewController : UITableViewController
- (void)showPackageDepiction:(ZBPackage *)package;
@end

NS_ASSUME_NONNULL_END
