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
#import <Queue/ZBQueueViewController.h>


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

@synthesize forwardedRepoBaseURL;
@synthesize forwardToPackageID;
@synthesize repoBusyList;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyLocalization];

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

- (void)applyLocalization {
    for(UINavigationController *vc in self.viewControllers) {
        assert([vc isKindOfClass:UINavigationController.class]);
        // This isn't exactly "best practice", but this way the text in IB isn't useless.
        vc.tabBarItem.title = NSLocalizedString([vc.tabBarItem.title capitalizedString], @"");
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([databaseManager needsToPresentRefresh]) {
        [databaseManager setNeedsToPresentRefresh:NO];
        
        ZBRefreshViewController *refreshController = [[ZBRefreshViewController alloc] initWithDropTables:true];
        [self presentViewController:refreshController animated:YES completion:nil];
    }
    
    //poor hack to get the tab bar to re-layout
    if (@available(iOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, 1, 0);
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, 0, 0);
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
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *navController = self.viewControllers[ZBTabPackages];
        ZBPackageListTableViewController *packagesController = navController.viewControllers[0];
        [packagesController refreshTable];
    });
}

- (void)setRepoRefreshIndicatorVisible:(BOOL)visible {
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *sourcesController = self.viewControllers[ZBTabSources];
        UITabBarItem *sourcesItem = [sourcesController tabBarItem];
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
        [(ZBRepoListTableViewController *)sourcesController.viewControllers[0] clearAllSpinners];
    });
}

#pragma mark - Database Delegate

- (void)setRepo:(NSString *)bfn busy:(BOOL)busy {
    if (bfn == NULL) return;
    if (!repoBusyList) repoBusyList = [NSMutableDictionary new];
    [repoBusyList setObject:@(busy) forKey:bfn];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ZBRepoListTableViewController *sourcesVC = (ZBRepoListTableViewController *)((UINavigationController *)self.viewControllers[ZBTabSources]).viewControllers[0];
        [sourcesVC setSpinnerVisible:busy forRepo:bfn];
    });
}

- (void)clearRepos {
    [repoBusyList removeAllObjects];
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
            ZBRefreshViewController *refreshController = [[ZBRefreshViewController alloc] initWithMessages:[self->errorMessages copy]];
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
        [self updateQueueNav];
    }
}

- (void)updateQueueNav {
    if (!queueNav) {
        queueNav = [[ZBQueueViewController alloc] init];
    }
}

- (void)updateQueueBarData:(int)count {
    queueNav.popupItem.title = [NSString stringWithFormat:@"%d %@", count, NSLocalizedString(count > 1 ? @"Packages in Queue" : @"Package in Queue", @"")];
    queueNav.popupItem.subtitle = NSLocalizedString(@"Tap to manage Queue", @"");
}

- (void)openQueue:(BOOL)openPopup {
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
    self.popupInteractionStyle = LNPopupInteractionStyleSnap;
    self.popupContentView.popupCloseButtonStyle = LNPopupCloseButtonStyleNone;
    [self presentPopupBarWithContentViewController:queueNav openPopup:openPopup animated:YES completion:nil];
}

- (void)updateQueueBar {
    [self checkQueueNav];
    int totalPackages = [ZBQueue count];
    LNPopupPresentationState state = self.popupPresentationState;
    if (totalPackages == 0) {
        queueNav.popupItem.title = NSLocalizedString(@"Queue cleared", @"");
        queueNav.popupItem.subtitle = nil;
        
        if (state == LNPopupPresentationStateOpen) {
            [[ZBAppDelegate tabBarController] dismissPopupBarAnimated:YES completion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBUpdateNavigationButtons" object:nil];
            }];
        }
    }
    else {
        if (state != LNPopupPresentationStateOpen && state != LNPopupPresentationStateTransitioning) {
            [self openQueue:NO];
        }
        [self updateQueueBarData:totalPackages];
    }
}

- (void)forwardToPackage {
    if (forwardToPackageID != NULL) { //this is pretty hacky
        NSString *urlString = [NSString stringWithFormat:@"zbra://packages/%@", forwardToPackageID];
        if (forwardedRepoBaseURL != NULL) {
            urlString = [urlString stringByAppendingFormat:@"?source=%@", forwardedRepoBaseURL];
            forwardedRepoBaseURL = NULL;
        }
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        forwardToPackageID = NULL;
    }
}

@end
