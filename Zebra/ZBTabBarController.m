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
#import <Database/ZBRefreshViewController.h>
#import <UIColor+GlobalColors.h>

@interface ZBTabBarController () {
    NSMutableArray *errorMessages;
    ZBDatabaseManager *databaseManager;
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

    NSInteger badgeValue = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    [self setPackageUpdateBadgeValue:(int)badgeValue];
    
    databaseManager = [ZBDatabaseManager sharedInstance];
    [databaseManager setDatabaseDelegate:self];
    [databaseManager updateDatabaseUsingCaching:true requested:false];
}

- (void)setPackageUpdateBadgeValue:(int)updates {
    [self updatePackagesTableView];
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBarItem *packagesTabBarItem = [self.tabBar.items objectAtIndex:2];
        
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
    UINavigationController *navController = self.viewControllers[2];
    ZBPackageListTableViewController *packagesController = navController.viewControllers[0];
    
    [packagesController refreshTable];
}

- (void)setRepoRefreshIndicatorVisible:(BOOL)visible {
    UINavigationController *sourcesController = self.viewControllers[1];
    UITabBarItem *sourcesItem = [sourcesController tabBarItem];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (visible) {
            sourcesItem.badgeValue = @"";
            
            for (UIView *badge in self.tabBar.subviews[2].subviews) {
                if ([NSStringFromClass([badge class]) isEqualToString:@"_UIBadgeView"]) {\
                    UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
                    [loadingView setColor:[UIColor whiteColor]];
                    
                    [loadingView setCenter:badge.center];
                    [loadingView startAnimating];
                    [badge addSubview:loadingView];
                }
            }
        }
        else {
            sourcesItem.badgeValue = nil;
        }
    });
    [(ZBRepoListTableViewController *)sourcesController.viewControllers[0] clearAllSpinners];
}

#pragma mark - Database Delegate

- (void)setRepo:(NSString *)bfn busy:(BOOL)busy {
    if (!repoBusyList) repoBusyList = [NSMutableDictionary new];
    
    ZBRepoListTableViewController *sourcesVC = (ZBRepoListTableViewController *)((UINavigationController *)self.viewControllers[1]).viewControllers[0];
    
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
