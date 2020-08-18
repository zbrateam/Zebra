//
//  ZBSourceListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 12/3/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@class ZBSource;

#import "ZBSourceVerificationDelegate.h"

@import UIKit;
#import <Database/ZBDatabaseDelegate.h>
#import <Extensions/ZBRefreshableTableViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceListTableViewController : ZBRefreshableTableViewController <ZBSourceVerificationDelegate> {
    NSMutableArray *sources;
    NSMutableDictionary <NSString *, NSNumber *> *sourceIndexes;
    NSMutableArray *sectionIndexTitles;
}
@property (readwrite, copy, nonatomic) NSArray *tableData;
- (void)setSpinnerVisible:(BOOL)visible forSource:(NSString *)bfn;
- (void)handleURL:(NSURL *)url;
- (void)addSource:(id)sender;
- (void)handleImportOf:(NSURL *)url;
- (void)updateCollation;
- (ZBSource * _Nullable)sourceAtIndexPath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END
