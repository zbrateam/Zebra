//
//  ZBSourceAddViewController.h
//  Zebra
//
//  Created by Wilson Styres on 6/1/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceAddViewController : UITableViewController <UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate>
- (instancetype)init;
- (instancetype)initWithURL:(NSURL *)url;
@end

NS_ASSUME_NONNULL_END
