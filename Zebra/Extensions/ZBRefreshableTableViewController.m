//
//  ZBRefreshableTableViewController.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 17/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBRefreshableTableViewController.h"
#import <ZBAppDelegate.h>
#import <ZBTabBarController.h>
#import <UIColor+Zebra.h>
#import <Database/ZBDatabaseManager.h>
#import <Sources/Helpers/ZBSource.h>
#import <Packages/Controllers/ZBPackageListTableViewController.h>

@interface ZBRefreshableTableViewController () {
    UIRefreshControl *refreshControl;
}
@end

@implementation ZBRefreshableTableViewController

@synthesize databaseManager;

+ (BOOL)supportRefresh {
    return YES;
}

- (void)cancelRefresh:(id)sender {
    [databaseManager cancelUpdates:self];
    [[ZBAppDelegate tabBarController] clearRepos];
    if (self.refreshControl.refreshing) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
        });
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    databaseManager = [ZBDatabaseManager sharedInstance];
    [self layoutNavigationButtons];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
//    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    if ([[self class] supportRefresh] && refreshControl == nil) {
        [databaseManager addDatabaseDelegate:self];
        refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshSources:) forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refreshControl;
    }
    [self updateRefreshView];
}

- (BOOL)updateRefreshView {
    if (self.refreshControl) {
        if ([databaseManager isDatabaseBeingUpdated]) {
            if (!self.refreshControl.refreshing) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.refreshControl beginRefreshing];
                    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y - self.refreshControl.frame.size.height) animated:YES];
                });
            }
            [self layoutNavigationButtonsRefreshing];
            return YES;
        }
    }
    return NO;
}

- (void)layoutNavigationButtonsRefreshing {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelRefresh:)];
        self.navigationItem.leftBarButtonItems = @[cancelButton];
    });
}

- (void)layoutNavigationButtonsNormal {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.leftBarButtonItems = @[];
    });
}

- (void)layoutNavigationButtons {
    if (self.refreshControl.refreshing) {
        [self layoutNavigationButtonsRefreshing];
    } else {
        [self layoutNavigationButtonsNormal];
    }
}

- (void)setRepoRefreshIndicatorVisible:(BOOL)visible {
    if (![[self class] supportRefresh]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [(ZBTabBarController *)self.tabBarController setRepoRefreshIndicatorVisible:visible];
    });
}

- (void)refreshSources:(id)sender {
    if (![[self class] supportRefresh] || [self updateRefreshView]) {
        return;
    }
    [self setRepoRefreshIndicatorVisible:YES];
    BOOL singleRepo = NO;
    if ([self respondsToSelector:@selector(repo)]) {
        ZBSource *repo = [(ZBPackageListTableViewController *)self repo];
        if ([repo repoID] > 0) {
            [databaseManager updateRepo:repo useCaching:YES];
            singleRepo = YES;
        }
    }
    if (!singleRepo) {
        [databaseManager updateDatabaseUsingCaching:YES userRequested:YES];
    }
}

- (void)didEndRefreshing {
    [self layoutNavigationButtons];
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    if (![[self class] supportRefresh]) {
        return;
    }
    if (packageUpdates != -1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [(ZBTabBarController *)self.tabBarController setPackageUpdateBadgeValue:packageUpdates];
        });
    }
    [self setRepoRefreshIndicatorVisible:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->refreshControl endRefreshing];
        [self didEndRefreshing];
    });
}

- (void)databaseStartedUpdate {
    if (![[self class] supportRefresh]) {
        return;
    }
    [self setRepoRefreshIndicatorVisible:YES];
    [self layoutNavigationButtons];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

@end
