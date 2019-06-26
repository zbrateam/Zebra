//
//  ZBRefreshableTableViewController.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 17/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Database/ZBDatabaseDelegate.h>
#import <Database/ZBDatabaseManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBRefreshableTableViewController : UITableViewController <ZBDatabaseDelegate>
@property (nonatomic, strong) ZBDatabaseManager *databaseManager;
- (void)setRepoRefreshIndicatorVisible:(BOOL)visible;
@end

NS_ASSUME_NONNULL_END
