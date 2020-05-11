//
//  ZBPackageListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ZBRefreshableTableViewController.h>
#import "ZBPackageDepictionViewController.h"

@class ZBSource;
@class ZBDatabaseManager;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageListTableViewController : ZBRefreshableTableViewController <UIViewControllerPreviewingDelegate>
@property (nonatomic, strong) ZBSource *source;
@property (nonatomic, strong) NSString *section;
@property (nonatomic, assign) BOOL batchLoad;
@property (nonatomic, assign) BOOL isPerformingBatchLoad;
@property (nonatomic, assign) BOOL continueBatchLoad;
@property (nonatomic, assign) int batchLoadCount;
@property (readwrite, copy, nonatomic) NSArray <NSArray *> *tableData;
- (void)refreshTable;
- (void)setDestinationVC:(NSIndexPath *)indexPath destination:(ZBPackageDepictionViewController *)destination;
- (NSArray *)contextMenuActionItemsForIndexPath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END
