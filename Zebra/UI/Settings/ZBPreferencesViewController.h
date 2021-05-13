//
//  ZBPreferencesViewController.h
//  Zebra
//
//  Created by absidue on 20-06-22.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBPreferencesViewController : UITableViewController
@property (nonatomic, readonly) NSArray <NSArray <NSDictionary *> *> *specifiers;
- (void)toggleSwitchAtIndexPath:(NSIndexPath *)indexPath;
- (void)chooseOptionAtIndexPath:(NSIndexPath *)indexPath previousIndexPath:(NSIndexPath *)previousIndexPath animated:(BOOL)animated;
- (void)chooseUnchooseOptionAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
