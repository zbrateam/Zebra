//
//  ZBChangesTableViewController.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 2/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZBDatabaseManager;

NS_ASSUME_NONNULL_BEGIN

@interface ZBChangesTableViewController : UITableViewController <UIViewControllerPreviewingDelegate>
@property (nonatomic, strong) ZBDatabaseManager *databaseManager;
@property (nonatomic, assign) BOOL batchLoad;
@property (nonatomic, assign) BOOL isPerformingBatchLoad;
@property (nonatomic, assign) BOOL continueBatchLoad;
@property (nonatomic, assign) int batchLoadCount;
@property (readwrite, copy, nonatomic) NSArray *tableData;
- (void)refreshTable;
@end

NS_ASSUME_NONNULL_END
