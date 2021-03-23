//
//  ZBSourceViewController.h
//  Zebra
//
//  Created by Wilson Styres on 3/20/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLSource;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceViewController : UITableViewController
- (id)initWithSource:(PLSource *)source;
@end

NS_ASSUME_NONNULL_END
