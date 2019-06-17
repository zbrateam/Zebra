//
//  ZBRefreshableTableViewController.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 17/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBRefreshableTableViewController.h"
#import <ZBTabBarController.h>
#import <Database/ZBDatabaseManager.h>

@implementation ZBRefreshableTableViewController

@synthesize databaseManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    databaseManager = [ZBDatabaseManager sharedInstance];
    
    //set up refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshSources:) forControlEvents:UIControlEventValueChanged];
}

- (void)setRepoRefreshIndicatorVisible:(BOOL)visible {
    [(ZBTabBarController *)self.tabBarController setRepoRefreshIndicatorVisible:visible];
}

- (void)refreshSources:(id)sender {
    [databaseManager addDatabaseDelegate:self];
    [self setRepoRefreshIndicatorVisible:true];
    [databaseManager updateDatabaseUsingCaching:true userRequested:true];
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

@end
