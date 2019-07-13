//
//  ZBTabBarController.m
//  Zebra
//
//  Created by Wilson Styres on 3/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBTabBarController.h"
#import <Database/ZBDatabaseManager.h>
#import <Packages/Controllers/ZBPackageListTableViewController.h>
#import <Repos/Controllers/ZBRepoListTableViewController.h>
#import <Packages/Helpers/ZBPackage.h>
#import <ZBAppDelegate.h>
#import <UITabBarItem.h>
#import <Database/ZBRefreshViewController.h>
#import <UIColor+GlobalColors.h>
#import "ZBTab.h"

@interface ZBTabBarController () {
    NSMutableArray *errorMessages;
    ZBDatabaseManager *databaseManager;
    UIActivityIndicatorView *indicator;
    BOOL sourcesUpdating;
}
@end

@implementation ZBTabBarController

@synthesize repoBusyList;

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(iOS 10.0, *)) {
        UITabBar.appearance.tintColor = [UIColor tintColor];
        UITabBarItem.appearance.badgeColor = [UIColor badgeColor];
    }
    
    self->indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
    CGRect indicatorFrame = self->indicator.frame;
    self->indicator.frame = indicatorFrame;
    self->indicator.color = [UIColor whiteColor];

    NSInteger badgeValue = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    [self setPackageUpdateBadgeValue:(int)badgeValue];
    
    databaseManager = [ZBDatabaseManager sharedInstance];
    if (![databaseManager needsToPresentRefresh]) {
        [databaseManager addDatabaseDelegate:self];
        [databaseManager updateDatabaseUsingCaching:true userRequested:false];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([databaseManager needsToPresentRefresh]) {
        [databaseManager setNeedsToPresentRefresh:false];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ZBRefreshViewController *refreshController = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
        refreshController.dropTables = YES;
        
        [self presentViewController:refreshController animated:true completion:nil];
    }
}

- (void)setPackageUpdateBadgeValue:(int)updates {
    [self updatePackagesTableView];
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBarItem *packagesTabBarItem = [self.tabBar.items objectAtIndex:ZBTabPackages];
        
        if (updates > 0) {
            [packagesTabBarItem setBadgeValue:[NSString stringWithFormat:@"%d", updates]];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:updates];
        }
        else {
            [packagesTabBarItem setBadgeValue:nil];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        }
    });
}

- (void)updatePackagesTableView {
    UINavigationController *navController = self.viewControllers[ZBTabPackages];
    ZBPackageListTableViewController *packagesController = navController.viewControllers[0];
    [packagesController refreshTable];
}

- (void)setRepoRefreshIndicatorVisible:(BOOL)visible {
    UINavigationController *sourcesController = self.viewControllers[ZBTabSources];
    UITabBarItem *sourcesItem = [sourcesController tabBarItem];
    dispatch_async(dispatch_get_main_queue(), ^{
        [sourcesItem setAnimatedBadge:visible];
        if (visible) {
            if (self->sourcesUpdating) {
                return;
            }
            sourcesItem.badgeValue = @"";
            
            UIView *badge = [[sourcesItem view] valueForKey:@"_badge"];
            self->indicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
            self->indicator.center = badge.center;
            [self->indicator startAnimating];
            [badge addSubview:self->indicator];
            self->sourcesUpdating = YES;
        }
        else {
            sourcesItem.badgeValue = nil;
            self->sourcesUpdating = NO;
        }
    });
    [(ZBRepoListTableViewController *)sourcesController.viewControllers[0] clearAllSpinners];
}

#pragma mark - Database Delegate

- (void)setRepo:(NSString *)bfn busy:(BOOL)busy {
    if (bfn == NULL) return;
    if (!repoBusyList) repoBusyList = [NSMutableDictionary new];
    
    ZBRepoListTableViewController *sourcesVC = (ZBRepoListTableViewController *)((UINavigationController *)self.viewControllers[ZBTabSources]).viewControllers[0];
    
    [repoBusyList setObject:@(busy) forKey:bfn];
    [sourcesVC setSpinnerVisible:busy forRepo:bfn];
}

- (void)databaseStartedUpdate {
    [self setRepoRefreshIndicatorVisible:true];
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    [self setPackageUpdateBadgeValue:packageUpdates];
    [self setRepoRefreshIndicatorVisible:false];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->errorMessages) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ZBRefreshViewController *refreshController = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
            refreshController.messages = self->errorMessages;
            
            [self presentViewController:refreshController animated:true completion:nil];
        }
    });
}

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    if (level == ZBLogLevelError) {
        if (!errorMessages) errorMessages = [NSMutableArray new];
        [errorMessages addObject:status];
    }
}

@end
