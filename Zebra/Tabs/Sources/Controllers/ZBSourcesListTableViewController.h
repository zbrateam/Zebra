//
//  ZBSourceListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 9/7/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBSourceManager;

#import <UIKit/UIKit.h>
#import <Extensions/ZBRefreshableTableViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourcesListTableViewController : ZBRefreshableTableViewController
@property (nonatomic, strong) ZBSourceManager *sourceManager;
@property (nonatomic, strong) NSArray *sources;
- (void)setSpinnerVisible:(BOOL)visible forBaseFileName:(NSString *)baseFileName;
- (void)handleURL:(NSURL *)url;
- (void)clearAllSpinners;
- (void)handleImportOf:(NSURL *)url;
@end

NS_ASSUME_NONNULL_END
