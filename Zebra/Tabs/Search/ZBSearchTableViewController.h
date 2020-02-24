//
//  ZBSearchTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 2/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSearchTableViewController : UITableViewController <UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>
@property (nonatomic, strong) UISearchController *searchController;
@end

NS_ASSUME_NONNULL_END
