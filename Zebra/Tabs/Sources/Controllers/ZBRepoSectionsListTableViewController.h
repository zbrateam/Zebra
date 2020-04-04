//
//  ZBRepoSectionsListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UICKeyChainStore.h"
@import SafariServices;

@class ZBSource;
@class ZBDatabaseManager;

NS_ASSUME_NONNULL_BEGIN

@interface ZBRepoSectionsListTableViewController : UITableViewController <UICollectionViewDelegate, UICollectionViewDataSource, SFSafariViewControllerDelegate>
@property (nonatomic, strong) ZBSource *repo;
- (id)initWithSource:(ZBSource *)source;
- (void)accountButtonPressed:(id)sender;
@end

NS_ASSUME_NONNULL_END
