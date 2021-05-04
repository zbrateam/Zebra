//
//  ZBErrorViewController.h
//  Zebra
//
//  Created by Wilson Styres on 5/4/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

@class PLSource;

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBErrorViewController : UITableViewController
- (instancetype)initWithSource:(PLSource *)source;
@end

NS_ASSUME_NONNULL_END
