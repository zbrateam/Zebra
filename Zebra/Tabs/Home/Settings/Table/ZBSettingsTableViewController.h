//
//  ZBSettingsTableViewController.h
//  Zebra
//
//  Created by absidue on 20-06-22.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Extensions/ZBTableViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSettingsTableViewController : ZBTableViewController

- (void)toggleSwitchAtIndexPath:(NSIndexPath *)indexPath;
- (void)chooseOptionAtIndexPath:(NSIndexPath *)indexPath previousIndexPath:(NSIndexPath *)previousIndexPath animated:(BOOL)animated;
- (void)chooseUnchooseOptionAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
