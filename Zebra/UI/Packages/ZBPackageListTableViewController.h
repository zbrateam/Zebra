//
//  ZBPackageListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@import UIKit;

@class ZBSource;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageListTableViewController : UITableViewController
@property (nonatomic, assign) BOOL batchLoad;
@property (nonatomic, assign) BOOL isPerformingBatchLoad;
@property (nonatomic, assign) BOOL continueBatchLoad;
@property (nonatomic, assign) int batchLoadCount;
@property (readwrite, copy, nonatomic) NSArray <NSArray *> *tableData;
- (instancetype)initWithSource:(ZBSource *)source;
- (instancetype)initWithSource:(ZBSource *)source section:(NSString *_Nullable)section;
- (void)refreshTable;
- (NSArray *)contextMenuActionItemsForIndexPath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END
