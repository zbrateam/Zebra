//
//  ZBSearchResultsTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 2/23/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSearchResultsTableViewController : UITableViewController
@property (nonatomic) NSArray *filteredResults;
@property (nonatomic) UINavigationController *navController;
- (id)initWithNavigationController:(UINavigationController *)controller;
@end

NS_ASSUME_NONNULL_END
