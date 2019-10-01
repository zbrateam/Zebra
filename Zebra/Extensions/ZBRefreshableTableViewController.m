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
#import <UIColor+GlobalColors.h>
#import <Database/ZBDatabaseManager.h>
#import <Repos/Helpers/ZBRepo.h>
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
    [self.databaseManager cancelUpdates:self];
    [[ZBAppDelegate tabBarController] clearRepos];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    databaseManager = [ZBDatabaseManager sharedInstance];
    if ([[self class] supportRefresh]) {
        [databaseManager addDatabaseDelegate:self];
        refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshSources:) forControlEvents:UIControlEventValueChanged];
        [self layoutNavigationButtons];
        [self updateRefreshView];
    }
}

- (BOOL)updateRefreshView {
    if (refreshControl) {
        self.refreshControl = refreshControl;
        if ([databaseManager isDatabaseBeingUpdated]) {
            if (!self.refreshControl.refreshing) {
                [self.refreshControl beginRefreshing];
            }
            [self layoutNavigationButtonsRefreshing];
            return YES;
        }
    } else {
        self.refreshControl = nil;
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
    [(ZBTabBarController *)self.tabBarController setRepoRefreshIndicatorVisible:visible];
}

- (void)refreshSources:(id)sender {
    if (![[self class] supportRefresh] || [self updateRefreshView]) {
        return;
    }
    [self setRepoRefreshIndicatorVisible:YES];
    BOOL singleRepo = NO;
    if ([self respondsToSelector:@selector(repo)]) {
        ZBRepo *repo = [(ZBPackageListTableViewController *)self repo];
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
        [(ZBTabBarController *)self.tabBarController setPackageUpdateBadgeValue:packageUpdates];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    [self updateRefreshView];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

@end
