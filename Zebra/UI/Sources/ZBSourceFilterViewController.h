//
//  ZBSourceFilterViewController.h
//  Zebra
//
//  Created by Wilson Styres on 1/1/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

@import UIKit;

#import <UI/Common/Delegates/ZBFilterDelegate.h>

@class ZBSourceFilter;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceFilterViewController : UITableViewController
- (instancetype)initWithFilter:(ZBSourceFilter *)filter delegate:(id <ZBFilterDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
