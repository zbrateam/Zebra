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
#import <ZBQueue.h>
#import "ZBTab.h"
@import LNPopupController;

@interface ZBTabBarController () {
    NSMutableArray *errorMessages;
    ZBDatabaseManager *databaseManager;
    UIActivityIndicatorView *indicator;
    BOOL sourcesUpdating;
    UINavigationController *queueNav;
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
        [databaseManager updateDatabaseUsingCaching:YES userRequested:NO];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateQueueBar) name:@"ZBUpdateQueueBar" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([databaseManager needsToPresentRefresh]) {
        [databaseManager setNeedsToPresentRefresh:NO];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ZBRefreshViewController *refreshController = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
        refreshController.messages = nil;
        refreshController.dropTables = YES;
        
        [self presentViewController:refreshController animated:YES completion:nil];
    }
}

- (void)setPackageUpdateBadgeValue:(int)updates {
    [self updatePackagesTableView];
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBarItem *packagesTabBarItem = [self.tabBar.items objectAtIndex:ZBTabPackages];
        
        if (updates > 0) {
            [packagesTabBarItem setBadgeValue:[NSString stringWithFormat:@"%d", updates]];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:updates];
        } else {
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
        } else {
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
    [self setRepoRefreshIndicatorVisible:YES];
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    if (packageUpdates != -1) {
        [self setPackageUpdateBadgeValue:packageUpdates];
    }
    [self setRepoRefreshIndicatorVisible:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->errorMessages) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ZBRefreshViewController *refreshController = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
            refreshController.messages = self->errorMessages;
            
            [self presentViewController:refreshController animated:YES completion:nil];
            self->errorMessages = nil;
        }
    });
}

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    if (level == ZBLogLevelError) {
        if (!errorMessages) errorMessages = [NSMutableArray new];
        [errorMessages addObject:status];
    }
}

- (void)checkQueueNav {
    if (queueNav == nil) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        queueNav = [storyboard instantiateViewControllerWithIdentifier:@"queueNavigationController"];
    }
}

- (void)updateQueueBarData {
    int totalPackages = 0;
    NSArray *actions = [[ZBQueue sharedInstance] actionsToPerform];
    for (NSString *string in actions) {
        totalPackages += [[ZBQueue sharedInstance] numberOfPackagesForQueue:string];
    }
    if (totalPackages == 0) {
        [[ZBAppDelegate tabBarController] dismissPopupBarAnimated:YES completion:nil];
        return;
    }
    queueNav.popupItem.title = [NSString stringWithFormat:@"%d %@ in Queue", totalPackages, totalPackages > 1 ? @"Packages" : @"Package"];
    queueNav.popupItem.subtitle = @"Tap to manage Queue";
}

- (void)openQueueBar:(BOOL)openPopup {
    [self checkQueueNav];
    LNPopupPresentationState state = self.popupPresentationState;
    if (state == LNPopupPresentationStateTransitioning) {
        return;
    }
    if (openPopup && state == LNPopupPresentationStateOpen) {
        return;
    }
    if (!openPopup && (state == LNPopupPresentationStateOpen || state == LNPopupPresentationStateClosed)) {
        return;
    }
    [self updateQueueBarData];
    self.popupInteractionStyle = LNPopupInteractionStyleSnap;
    self.popupContentView.popupCloseButtonStyle = LNPopupCloseButtonStyleNone;
    [self presentPopupBarWithContentViewController:queueNav openPopup:openPopup animated:YES completion:nil];
}

- (void)updateQueueBar {
    [self checkQueueNav];
    LNPopupPresentationState state = self.popupPresentationState;
    if (state != LNPopupPresentationStateOpen && state != LNPopupPresentationStateTransitioning) {
        [self openQueueBar:NO];
    }
    [self updateQueueBarData];
}

@end
