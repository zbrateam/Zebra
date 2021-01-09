//
//  ZBSourceListViewController.h
//  Zebra
//
//  Created by Wilson Styres on 1/1/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

@import UIKit;

#import <UI/Common/Delegates/ZBFilterDelegate.h>

@class ZBSource;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceListViewController : UITableViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UIViewControllerTransitioningDelegate, ZBFilterDelegate>
@property NSArray <ZBSource *> *sources;
#pragma mark - Initializers
- (instancetype)initWithSources:(NSArray <ZBSource *> *)sources;
#pragma mark - URL Handling
- (void)handleURL:(NSURL *)url;
- (void)handleImportOf:(NSURL *)url;
@end

NS_ASSUME_NONNULL_END
