//
//  ZBSidebarController.h
//  Zebra
//
//  Created by Wilson Styres on 3/31/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSidebarController : UISplitViewController <UITableViewDelegate, UITableViewDataSource, NSToolbarDelegate>
@property (nonatomic) NSArray <UIViewController *> *controllers;
@end

NS_ASSUME_NONNULL_END
