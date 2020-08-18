//
//  ZBChangesTableViewController.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 2/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@import UIKit;
#import <ZBRefreshableTableViewController.h>
#import "ZBNewsCollectionViewCell.h"
@import SafariServices;
@class ZBDatabaseManager;

NS_ASSUME_NONNULL_BEGIN

@interface ZBChangesTableViewController : ZBRefreshableTableViewController <UIViewControllerPreviewingDelegate, UICollectionViewDelegate, UICollectionViewDataSource, SFSafariViewControllerDelegate>
@property (nonatomic, assign) BOOL batchLoad;
@property (nonatomic, assign) BOOL isPerformingBatchLoad;
@property (nonatomic, assign) BOOL continueBatchLoad;
@property (nonatomic, assign) int batchLoadCount;
@property (readwrite, copy, nonatomic) NSArray *tableData;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property NSMutableArray *redditPosts;
- (void)refreshTable;
@end

NS_ASSUME_NONNULL_END
