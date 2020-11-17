//
//  ZBPackageFilterViewController.h
//  Zebra
//
//  Created by Wilson Styres on 11/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBFilterDelegate.h"
#import <UI/Common/Delegates/ZBSelectionDelegate.h>

@class ZBPackageFilter;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageFilterViewController : UITableViewController <ZBSelectionDelegate>
- (instancetype)initWithFilter:(ZBPackageFilter *)filter delegate:(id <ZBFilterDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
