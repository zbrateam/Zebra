//
//  ZBAuthorSelectorTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 3/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBAuthorSelectorTableViewController : UITableViewController
@property void (^authorsSelected)(NSArray *selectedAuthors);
@end

NS_ASSUME_NONNULL_END
