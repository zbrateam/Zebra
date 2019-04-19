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

@interface ZBTabBarController ()

@end

@implementation ZBTabBarController

@synthesize repoBusyList;

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(iOS 10.0, *)) {
        UITabBarItem.appearance.badgeColor = [UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0];
    }

    NSInteger badgeValue = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    [self setPackageUpdateBadgeValue:(int)badgeValue];
    
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
    [databaseManager setDatabaseDelegate:self];
    [databaseManager updateDatabaseUsingCaching:true requested:false];
}

- (void)setPackageUpdateBadgeValue:(int)updates {
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
}

@end
