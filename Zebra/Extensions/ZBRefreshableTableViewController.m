//
//  ZBRefreshableTableViewController.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 17/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBRefreshableTableViewController.h"
#import <ZBAppDelegate.h>
#import <Tabs/ZBTabBarController.h>
#import <Database/ZBDatabaseManager.h>
#import <Tabs/Sources/Helpers/ZBSource.h>
#import <Tabs/Packages/Controllers/ZBPackageListTableViewController.h>
#import <ZBDevice.h>

@interface ZBRefreshableTableViewController () {
    UIRefreshControl *refreshControl;
}
@end

@implementation ZBRefreshableTableViewController

- (BOOL)supportRefresh {
    return YES;
}

- (void)cancelRefresh:(id)sender {
    [sourceManager cancelSourceRefresh];
    if (self.refreshControl.refreshing) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
            [self didEndRefreshing];
//            [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
        });
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    sourceManager = [ZBSourceManager sharedInstance];
    databaseManager = [ZBDatabaseManager sharedInstance];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    [self layoutNavigationButtons];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutNavigationButtons) name:@"ZBUpdateNavigationButtons" object:nil];
    
//    if (self.refreshControl) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if ([ZBDevice darkModeEnabled]) {
//                [self.refreshControl setTintColor:[UIColor whiteColor]];
//            }
//            else {
//                [self.refreshControl setTintColor:[UIColor blackColor]];
//            }
//        });
//    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.extendedLayoutIncludesOpaqueBars = YES;
    [refreshControl endRefreshing];
    
    if ([self supportRefresh] && refreshControl == nil) {
        [sourceManager addDelegate:self];
        refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshSources:) forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refreshControl;
    }
//    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    [self updateRefreshView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.refreshControl) {
        [self.refreshControl endRefreshing];
    }
}

- (BOOL)updateRefreshView {
    if (self.refreshControl) {
        if ([sourceManager isRefreshInProgress]) {
            if (!self.refreshControl.refreshing) {
                dispatch_async(dispatch_get_main_queue(), ^{
//                    if ([ZBDevice darkModeEnabled]) {
//                        [self.refreshControl setTintColor:[UIColor whiteColor]];
//                    }
//                    else {
//                        [self.refreshControl setTintColor:[UIColor blackColor]];
//                    }
                    
                    [self.refreshControl beginRefreshing];
                    [self didEndRefreshing];
//                    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y - self.refreshControl.frame.size.height) animated:YES];
                });
            }
            [self layoutNavigationButtonsRefreshing];
            return YES;
        }
    }
    [self layoutNavigationButtonsNormal];
    return NO;
}

- (void)layoutNavigationButtonsRefreshing {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancelRefresh:)];
        self.navigationItem.leftBarButtonItems = @[cancelButton];
    });
}

- (void)layoutNavigationButtonsNormal {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.leftBarButtonItems = @[];
    });
}

- (void)layoutNavigationButtons {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.refreshControl.refreshing) {
            [self layoutNavigationButtonsRefreshing];
        } else {
            [self layoutNavigationButtonsNormal];
        }
    });
}

- (void)setSourceRefreshIndicatorVisible:(BOOL)visible {
    if (![self supportRefresh]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [(ZBTabBarController *)self.tabBarController setSourceRefreshIndicatorVisible:visible];
    });
}

- (void)refreshSources:(id)sender {
    if (![self supportRefresh] || [self updateRefreshView]) {
        return;
    }
    [self setEditing:NO animated:NO];
    [self setSourceRefreshIndicatorVisible:YES];
    [sourceManager refreshSourcesUsingCaching:YES userRequested:YES error:nil];
    [self updateRefreshView];
}

- (void)didEndRefreshing {
    [self layoutNavigationButtons];
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    if (![self supportRefresh]) {
        return;
    }
    [self setSourceRefreshIndicatorVisible:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (packageUpdates != -1) {
            [(ZBTabBarController *)self.tabBarController setPackageUpdateBadgeValue:packageUpdates];
        }
        [self->refreshControl endRefreshing];
        [self didEndRefreshing];
//        [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    });
}

- (void)databaseStartedUpdate {
    if (![self supportRefresh]) {
        return;
    }
    [self setSourceRefreshIndicatorVisible:YES];
    [self layoutNavigationButtons];
}

- (void)finishedRefreshForSource:(ZBBaseSource *)source warnings:(NSArray *)warnings errors:(NSArray *)errors {
    // Nothing at the moment
}

- (void)progressUpdateForSource:(ZBBaseSource *)source progress:(CGFloat)progress {
    // Nothing at the moment
}

- (void)startedRefreshForSource:(ZBBaseSource *)source {
    // Nothing at the moment
}

@end
