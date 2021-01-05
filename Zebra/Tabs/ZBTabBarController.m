//
//  ZBTabBarController.m
//  Zebra
//
//  Created by Wilson Styres on 3/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBTabBarController.h"

#import <Managers/ZBSourceManager.h>
#import <Model/ZBSource.h>
#import <UI/Packages/ZBPackageListViewController.h>
#import <UI/Sources/ZBSourceListViewController.h>
#import <UI/Search/ZBSearchViewController.h>

#import "ZBTab.h"
//#import "Packages/Helpers/ZBPackage.h"
#import <ZBAppDelegate.h>
#import <Headers/UITabBarItem.h>
#import <Extensions/UIColor+GlobalColors.h>
#import <Queue/ZBQueue.h>
#import <Queue/ZBQueueViewController.h>
#import <ZBDevice.h>

@import LNPopupController;

@interface ZBTabBarController () {
    ZBSourceManager *sourceManager;
    UIActivityIndicatorView *sourceRefreshIndicator;
}

@property (nonatomic) UINavigationController *popupController;
@property (nonatomic, readonly) ZBQueueViewController *queueController;
@end

@implementation ZBTabBarController
@synthesize queueController = _queueController;
@synthesize popupController = _popupController;

@synthesize forwardedSourceBaseURL;
@synthesize forwardToPackageID;

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"tabController"];
    
    if (self) {
        sourceManager = [ZBSourceManager sharedInstance];
        
        UITabBar.appearance.tintColor = [UIColor accentColor];
        UITabBarItem.appearance.badgeColor = [UIColor badgeColor];
        
        self.delegate = (ZBAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        sourceRefreshIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
        sourceRefreshIndicator.color = [UIColor whiteColor];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startedSourceRefresh:) name:ZBStartedSourceRefreshNotification object:NULL];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedSourceRefresh) name:ZBFinishedSourceRefreshNotification object:NULL];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatesAvailable:) name:ZBUpdatesAvailableNotification object:NULL];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSError *refreshError = NULL;
    [sourceManager refreshSourcesUsingCaching:YES userRequested:NO error:&refreshError];
    if (refreshError) {
        [ZBAppDelegate sendErrorToTabController:refreshError.localizedDescription];
    }
    
    NSError *error = NULL;
    if ([ZBDevice isSlingshotBroken:&error]) { //error should never be null if the function returns YES
        [ZBAppDelegate sendErrorToTabController:error.localizedDescription];
    }
    
    // Temporary, remove when all views are decoupled from storyboard
    UINavigationController *sourcesNavController = self.viewControllers[ZBTabSources];
    [sourcesNavController setViewControllers:@[[[ZBSourceListViewController alloc] init]] animated:NO];
    
    UINavigationController *packagesNavController = self.viewControllers[ZBTabPackages];
    [packagesNavController setViewControllers:@[[[ZBPackageListViewController alloc] initWithSource:[ZBSource localSource]]] animated:NO];
    
    UINavigationController *searchNavController = self.viewControllers[ZBTabSearch];
    [searchNavController setViewControllers:@[[[ZBSearchViewController alloc] init]] animated:NO];
}

- (void)setPackageUpdateBadgeValue:(NSInteger)updates {
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBarItem *packagesTabBarItem = [self.tabBar.items objectAtIndex:ZBTabPackages];
        
        if (updates > 0) {
            [packagesTabBarItem setBadgeValue:[NSString stringWithFormat:@"%ld", (long)updates]];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:updates];
        } else {
            [packagesTabBarItem setBadgeValue:nil];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        }
    });
}

- (void)setSourceRefreshIndicatorVisible:(BOOL)visible {
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *sourcesController = self.viewControllers[ZBTabSources];
        UITabBarItem *sourcesItem = [sourcesController tabBarItem];
        [sourcesItem setAnimatedBadge:visible];
        if (visible) {
            sourcesItem.badgeValue = @"";
            
            UIView *badge = [[sourcesItem view] valueForKey:@"_badge"];
            self->sourceRefreshIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
            self->sourceRefreshIndicator.center = badge.center;
            [self->sourceRefreshIndicator startAnimating];
            [badge addSubview:self->sourceRefreshIndicator];
        } else {
            sourcesItem.badgeValue = nil;
        }
    });
}

#pragma mark - Source Delegate

- (void)startedSourceRefresh:(NSNotification *)notification {
    if (![notification.userInfo[@"hidden"] boolValue]) {
        [self setSourceRefreshIndicatorVisible:YES];
    }
}

- (void)finishedSourceRefresh {
    [self setSourceRefreshIndicatorVisible:NO];
}

- (void)updatesAvailable:(NSNotification *)notification {
    NSUInteger numberOfUpdates = [notification.userInfo[@"updates"] unsignedIntegerValue];
    [self setPackageUpdateBadgeValue:numberOfUpdates];
}

- (void)forwardToPackage {
    if (forwardToPackageID != NULL) { //this is pretty hacky
        NSString *urlString = [NSString stringWithFormat:@"zbra://packages/%@", forwardToPackageID];
        if (forwardedSourceBaseURL != nil) {
            urlString = [urlString stringByAppendingFormat:@"?source=%@", forwardedSourceBaseURL];
            forwardedSourceBaseURL = nil;
        }
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
        forwardToPackageID = nil;
    }
}

#pragma mark - Queue Popup Bar

- (UINavigationController *)popupController {
    if (!_popupController) {
        _popupController = [[UINavigationController alloc] initWithRootViewController:self.queueController];
    }
    
    return _popupController;
}

- (ZBQueueViewController *)queueController {
    if (!_queueController) {
        _queueController = [ZBQueueViewController new];
    }
    
    return _queueController;
}

- (void)updateQueueBar {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateQueueBarPackageCount:[ZBQueue count]];
        
        LNPopupPresentationState state = self.popupPresentationState;
        if (state != LNPopupPresentationStateOpen && state != LNPopupPresentationStateTransitioning) {
            [self openQueue:NO];
        }
        else {
            [[self popupBar] setNeedsLayout];
        }
    });
}

- (void)updateQueueBarPackageCount:(int)count {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (count > 0) {
            self.popupController.popupItem.title = count > 1 ? [NSString stringWithFormat:NSLocalizedString(@"%d Packages Queued", @""), count] : [NSString stringWithFormat:NSLocalizedString(@"%d Package Queued", @""), count];
            self.popupController.popupItem.subtitle = NSLocalizedString(@"Tap to manage", @"");
        }
        else {
            self.popupController.popupItem.title = NSLocalizedString(@"No Packages Queued", @"");
            self.popupController.popupItem.subtitle = nil;
        }
    });
}

- (void)openQueue:(BOOL)openPopup {
    dispatch_async(dispatch_get_main_queue(), ^{
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
        [self presentPopupBarWithContentViewController:self.popupController openPopup:openPopup animated:YES completion:nil];
    });
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
        
        [self presentViewController:clearQueue animated:YES completion:nil];
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
            [self dismissPopupBarAnimated:YES completion:^{
                self.popupController = nil;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBUpdateNavigationButtons" object:nil];
            }];
        }
    });
}

- (void)requestSourceRefresh {
    if (sourceManager.refreshInProgress) return;
    
    [sourceManager refreshSourcesUsingCaching:YES userRequested:YES error:nil];
}

@end
