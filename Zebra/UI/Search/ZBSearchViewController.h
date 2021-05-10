//
//  ZBSearchViewController.h
//  Zebra
//
//  Created by Wilson Styres on 2/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSearchViewController : UITableViewController <UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate>
- (instancetype)initWithSearchTerm:(NSString *)term;
- (void)handleURL:(NSURL *_Nullable)url;
@end

NS_ASSUME_NONNULL_END
