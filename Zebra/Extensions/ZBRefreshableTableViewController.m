//
//  ZBRefreshableTableViewController.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 17/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBRefreshableTableViewController.h"
#import <ZBTabBarController.h>
#import <UIColor+GlobalColors.h>
#import <Database/ZBDatabaseManager.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Packages/Controllers/ZBPackageListTableViewController.h>

@implementation ZBRefreshableTableViewController

@synthesize databaseManager;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    databaseManager = [ZBDatabaseManager sharedInstance];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshSources:) forControlEvents:UIControlEventValueChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
}

- (void)setRepoRefreshIndicatorVisible:(BOOL)visible {
    [(ZBTabBarController *)self.tabBarController setRepoRefreshIndicatorVisible:visible];
}

- (void)refreshSources:(id)sender {
    if ([databaseManager isDatabaseBeingUpdated])
        return;
    [databaseManager addDatabaseDelegate:self];
    [self setRepoRefreshIndicatorVisible:true];
    BOOL singleRepo = NO;
    if ([self respondsToSelector:@selector(repo)]) {
        ZBRepo *repo = [(ZBPackageListTableViewController *)self repo];
        if ([repo repoID] > 0) {
            [databaseManager updateRepo:repo useCaching:true];
            singleRepo = YES;
        }
    }
    if (!singleRepo) {
        [databaseManager updateDatabaseUsingCaching:true userRequested:true];
    }
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    [(ZBTabBarController *)self.tabBarController setPackageUpdateBadgeValue:packageUpdates];
    [self setRepoRefreshIndicatorVisible:false];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

- (void)databaseStartedUpdate {
    [self setRepoRefreshIndicatorVisible:true];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

- (void)darkMode:(NSNotification *)notification {
    [self.tableView reloadData];
}

@end
