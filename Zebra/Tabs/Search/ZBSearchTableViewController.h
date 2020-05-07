//
//  ZBSearchTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 2/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Extensions/ZBTableViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSearchTableViewController : ZBTableViewController <UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>
@property (nonatomic, strong) UISearchController *searchController;
- (void)handleURL:(NSURL *_Nullable)url;
@end

NS_ASSUME_NONNULL_END
