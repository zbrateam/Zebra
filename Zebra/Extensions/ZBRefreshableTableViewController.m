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
    NSArray <UIBarButtonItem *> *savedLeftButtons;
    NSArray <UIBarButtonItem *> *savedRightButtons;
}
@end

@implementation ZBRefreshableTableViewController

+ (BOOL)supportRefresh {
    return YES;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    
    if (self) {
        sourceManager = [ZBSourceManager sharedInstance];
        [sourceManager addDelegate:self];
        
        if ([[self class] supportRefresh]) {
            self.refreshControl = [[UIRefreshControl alloc] init];
            [self.refreshControl addTarget:self action:@selector(refreshSources:) forControlEvents:UIControlEventValueChanged];
        }
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self layoutNavigationButtons];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([[self class] supportRefresh] && self.refreshControl.refreshing) {
        [self.refreshControl endRefreshing];
    }
}

- (void)cancelRefresh:(id)sender {
    [sourceManager cancelSourceRefresh];
    if (self.refreshControl.refreshing) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
        });
    }
}

- (void)layoutNavigationButtonsRefreshing {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancelRefresh:)];
        self.navigationItem.leftBarButtonItems = @[cancelButton];
    });
}

- (void)layoutNavigationButtonsNormal {
    dispatch_async(dispatch_get_main_queue(), ^{
//        self.navigationItem.leftBarButtonItems = @[];
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

- (void)refreshSources:(id)sender {
    if (![[self class] supportRefresh] || [sourceManager isRefreshInProgress]) {
        return;
    }
    [self setEditing:NO animated:YES];
    
    [sourceManager refreshSourcesUsingCaching:YES userRequested:YES error:nil];
}

- (void)startedSourceRefresh {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[self class] supportRefresh] && !self.refreshControl.refreshing) {
            [self.refreshControl beginRefreshing];
        }
    });
}

- (void)finishedSourceRefresh {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[self class] supportRefresh] && self.refreshControl.refreshing) {
            [self.refreshControl endRefreshing];
        }
    });
}

@end
