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
#import <Sources/Controllers/ZBSourceListTableViewController.h>
#import <Packages/Helpers/ZBPackage.h>
#import <ZBAppDelegate.h>
#import <UITabBarItem.h>
#import <Database/ZBRefreshViewController.h>
#import <UIColor+GlobalColors.h>
#import <ZBQueue.h>
#import "ZBTab.h"
#import <Queue/ZBQueueViewController.h>
#import <ZBDevice.h>


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

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"tabController"];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyLocalization];

    if (@available(iOS 10.0, *)) {
        UITabBar.appearance.tintColor = [UIColor accentColor];
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
    
    NSError *error;
    if ([ZBDevice isSlingshotBroken:&error]) { //error should never be null if the function returns YES
        [ZBAppDelegate sendErrorToTabController:error.localizedDescription];
    }
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
        
        ZBRefreshViewController *refreshController = [[ZBRefreshViewController alloc] initWithDropTables:YES];
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
        [self clearRepos];
    });
}

#pragma mark - Database Delegate

- (void)setRepo:(NSString *)bfn busy:(BOOL)busy {
    if (bfn == NULL) return;
    if (!repoBusyList) repoBusyList = [NSMutableDictionary new];
    [repoBusyList setObject:@(busy) forKey:bfn];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ZBSourceListTableViewController *sourcesVC = (ZBSourceListTableViewController *)((UINavigationController *)self.viewControllers[ZBTabSources]).viewControllers[0];
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

#pragma mark - Queue Popup Bar

- (void)checkQueueNav {
    if (!queueNav) {
        queueNav = [[UINavigationController alloc] initWithRootViewController:[[ZBQueueViewController alloc] init]];
        [[LNPopupBar appearance] setTranslucent:YES];
    }
}

- (void)updateQueueBarColors {
//    if ([ZBDevice darkModeEnabled]) {
//        [[LNPopupBar appearance] setBackgroundStyle:UIBlurEffectStyleDark];
//        [[LNPopupBar appearance] setBackgroundColor:[UIColor blackColor]];
//        
//        [[LNPopupBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
//        [[LNPopupBar appearance] setSubtitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
//    }
//    else {
//        [[LNPopupBar appearance] setBackgroundStyle:UIBlurEffectStyleLight];
//        [[LNPopupBar appearance] setBackgroundColor:[UIColor whiteColor]];
//        
//        [[LNPopupBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]}];
//        [[LNPopupBar appearance] setSubtitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]}];
//    }
}

- (void)updateQueueBar {
    [self checkQueueNav];
    [self updateQueueBarPackageCount:[ZBQueue count]];
    
    [self updateQueueBarColors];
    
    LNPopupPresentationState state = self.popupPresentationState;
    if (state != LNPopupPresentationStateOpen && state != LNPopupPresentationStateTransitioning) {
        [self openQueue:NO];
    }
    else {
        [[self popupBar] setNeedsLayout];
    }
}

- (void)updateQueueBarPackageCount:(int)count {
    if (count > 0) {
        queueNav.popupItem.title = count > 1 ? [NSString stringWithFormat:NSLocalizedString(@"%d Packages Queued", @""), count] : [NSString stringWithFormat:NSLocalizedString(@"%d Package Queued", @""), count];
//        queueNav.popupItem.image = [UIImage imageNamed:@"Unknown"];
        queueNav.popupItem.subtitle = NSLocalizedString(@"Tap to manage", @"");
    }
    else {
        queueNav.popupItem.title = NSLocalizedString(@"No Packages Queued", @"");
        queueNav.popupItem.subtitle = nil;
    }
}

- (void)openQueue:(BOOL)openPopup {
    [self checkQueueNav];
    
    LNPopupPresentationState state = self.popupPresentationState;
    if (state == LNPopupPresentationStateTransitioning || (openPopup && state == LNPopupPresentationStateOpen) || (!openPopup && (state == LNPopupPresentationStateOpen || state == LNPopupPresentationStateClosed))) {
        return;
    }

    self.popupInteractionStyle = LNPopupInteractionStyleSnap;
    self.popupContentView.popupCloseButtonStyle = LNPopupCloseButtonStyleNone;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHoldGesture:)];
    longPress.minimumPressDuration = 1;
    longPress.delegate = self;
    
    [self.popupBar addGestureRecognizer:longPress];
    
    [self presentPopupBarWithContentViewController:queueNav openPopup:openPopup animated:YES completion:nil];
}

- (void)handleHoldGesture:(UILongPressGestureRecognizer *)gesture {
    if (UIGestureRecognizerStateBegan == gesture.state) {
        UIAlertController *clearQueue = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Clear Queue", @"") message:NSLocalizedString(@"Are you sure you want to clear the Queue?", @"") preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            [[ZBQueue sharedQueue] clear];
        }];
        [clearQueue addAction:yesAction];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleCancel handler:nil];
        [clearQueue addAction:noAction];
        
        [self presentViewController:clearQueue animated:true completion:nil];
    }
    
}

- (BOOL)isQueueBarAnimating {
    return self.popupPresentationState == LNPopupPresentationStateTransitioning;
}

- (void)closeQueue {
    dispatch_async(dispatch_get_main_queue(), ^{
        LNPopupPresentationState state = self.popupPresentationState;
        if (state == LNPopupPresentationStateOpen || state == LNPopupPresentationStateTransitioning || state == LNPopupPresentationStateClosed) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
            [[ZBAppDelegate tabBarController] dismissPopupBarAnimated:YES completion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBUpdateNavigationButtons" object:nil];
            }];
        }
    });
}

@end
