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

@synthesize updates;
@synthesize hasUpdates;
@synthesize repoBusyList;

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(iOS 10.0, *)) {
        UITabBarItem.appearance.badgeColor = [UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0];
    }

//    [self performBackgroundRefresh:false];
//    [self performBackgroundRefresh:false completion:^(BOOL success) {
//        if (!success) {
//            NSLog(@"Error!");
//        }
//        else {
//            NSDate *newUpdateDate = [NSDate date];
//            [[NSUserDefaults standardUserDefaults] setObject:newUpdateDate forKey:@"lastUpdatedDate"];
//        }
//    }];
}

- (void)performBackgroundRefresh:(BOOL)requested {
    BOOL timePassed = false;
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
    [databaseManager setDatabaseDelegate:self];

    if (!requested) {
        NSDate *currentDate = [NSDate date];
        NSDate *lastUpdatedDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:@"lastUpdatedDate"];

        if (lastUpdatedDate != nil) {
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags fromDate:lastUpdatedDate toDate:currentDate options:0];

            timePassed = ([components minute] >= 30); //might need to be less
        }
        else {
            timePassed = true;
        }
    }

    if (requested || timePassed) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [self setRepoRefreshIndicatorVisible:true];
            [databaseManager updateDatabaseUsingCaching:true];
        });
    }
    else {
        [databaseManager importLocalPackages:^(BOOL success) {
            [self checkForPackageUpdates];
        }];
    }
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

- (void)checkForPackageUpdates {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(checkForPackageUpdates) withObject:nil waitUntilDone:false];
    }
    else {
        ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
        updates = [databaseManager packagesWithUpdates];

        UITabBarItem *packagesTabBarItem = [self.tabBar.items objectAtIndex:2];
        if ([updates count] != 0) {
            hasUpdates = TRUE;
//            NSLog(@"Has Updates");
            [packagesTabBarItem setBadgeValue:[NSString stringWithFormat:@"%d", (int)[updates count]]];
            if (@available(iOS 10.0, *)) {
                [packagesTabBarItem setBadgeColor:[UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0]];
            }

            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[updates count]];

            UINavigationController *packageNavController = self.viewControllers[2];
            ZBPackageListTableViewController *packageVC = packageNavController.viewControllers[0];
            [packageVC refreshTable];
        }
        else {
//            NSLog(@"No Updates");
            hasUpdates = FALSE;
            [packagesTabBarItem setBadgeValue:nil];

            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];

            UINavigationController *packageNavController = self.viewControllers[2];
            ZBPackageListTableViewController *packageVC = packageNavController.viewControllers[0];
            [packageVC refreshTable];
        }
    }
}

- (void)setRepo:(NSString *)bfn busy:(BOOL)busy {
    if (!repoBusyList) repoBusyList = [NSMutableDictionary new];
    
    ZBRepoListTableViewController *sourcesVC = (ZBRepoListTableViewController *)((UINavigationController *)self.viewControllers[1]).viewControllers[0];
    
    [repoBusyList setObject:@(busy) forKey:bfn];
    [sourcesVC setSpinnerVisible:busy forRepo:bfn];
}

- (void)databaseCompletedUpdate:(BOOL)success {
    NSLog(@"Database Update Completed Tab");
    if (success) {
        NSDate *newUpdateDate = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setObject:newUpdateDate forKey:@"lastUpdatedDate"];
        [self setRepoRefreshIndicatorVisible:false];
        
//        [self checkForPackageUpdates];
    }
}

- (BOOL)doesPackageIDHaveUpdate:(NSString *)packageID {
    for (ZBPackage *package in updates) {
        if ([[package identifier] isEqual:packageID]) {
            return true;
        }
    }
    return false;
}

@end
