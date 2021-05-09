//
//  ZBSidebarController.h
//  Zebra
//
//  Created by Wilson Styres on 3/31/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_MACCATALYST
@interface ZBSidebarController : UISplitViewController <UITableViewDelegate, UITableViewDataSource, NSToolbarDelegate, UINavigationControllerDelegate, UISearchBarDelegate>
@property (nonatomic) BOOL showBackButton;
- (void)addToolbarItem:(NSString *)identifier;
- (void)removeToolbarItem:(NSString *)identifier;
#else
@interface ZBSidebarController : UISplitViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
#endif
@property (nonatomic) NSArray <UIViewController *> *controllers;
- (void)showRefreshIndicator;
- (void)hideRefreshIndicator;
@end

NS_ASSUME_NONNULL_END
