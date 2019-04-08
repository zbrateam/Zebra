//
//  ZBRepoListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 12/3/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBRepoListTableViewController : UITableViewController
- (void)setSpinnerVisible:(BOOL)visible forRow:(NSInteger)row;
- (void)clearAllSpinners;
@end

NS_ASSUME_NONNULL_END
