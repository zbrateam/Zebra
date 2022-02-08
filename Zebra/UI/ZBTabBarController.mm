//
//  ZBTabBarController.m
//  Zebra
//
//  Created by Wilson Styres on 3/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBTabBarController.h"

#import <UI/Home/ZBHomeViewController.h>
#import <UI/Packages/ZBPackageListViewController.h>
#import <UI/Sources/ZBSourceListViewController.h>
#import <UI/Search/ZBSearchViewController.h>

#import "ZBTab.h"
//#import "Packages/Helpers/ZBPackage.h"
#import <ZBAppDelegate.h>
#import <Headers/UITabBarItem.h>
#import "Zebra-Swift.h"
#import <UI/Queue/ZBQueueViewController.h>

#import <Plains/Plains.h>

#import <LNPopupController/LNPopupController.h>

@interface ZBTabBarController () {
    UIActivityIndicatorView *sourceRefreshIndicator;
    NSUInteger queueCount;
    NSUInteger updates;
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
    self = [super init];
    
    if (self) {
        UITabBar.appearance.tintColor = [UIColor accentColor];
        UITabBarItem.appearance.badgeColor = [UIColor badgeColor];
        
        self.delegate = (ZBAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        sourceRefreshIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)12];
        sourceRefreshIndicator.color = [UIColor whiteColor];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateQueue:) name:PLQueueUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUpdates:) name:PLDatabaseRefreshNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUpdates:) name:PLDatabaseImportNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showRefreshIndicator) name:PLStartedSourceRefreshNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideRefreshIndicator) name:PLFinishedSourceRefreshNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationController *homeNavController = [[UINavigationController alloc] init];
    [homeNavController setViewControllers:@[[[ZBHomeViewController alloc] init]] animated:NO];
    [homeNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Home" image:[UIImage imageNamed:@"Home"] tag:0]];
    [homeNavController.navigationBar setPrefersLargeTitles:YES];
    
    UINavigationController *sourcesNavController = [[UINavigationController alloc] init];
    [sourcesNavController setViewControllers:@[[[ZBSourceListViewController alloc] init]] animated:NO];
    [sourcesNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Sources" image:[UIImage imageNamed:@"Sources"] tag:1]];
    [sourcesNavController.navigationBar setPrefersLargeTitles:YES];
    
    UINavigationController *packagesNavController = [[UINavigationController alloc] init];
    [packagesNavController setViewControllers:@[[[ZBPackageListViewController alloc] init]] animated:NO];
    [packagesNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Installed" image:[UIImage imageNamed:@"Packages"] tag:2]];
    [packagesNavController.navigationBar setPrefersLargeTitles:YES];
    
    UINavigationController *searchNavController = [[UINavigationController alloc] init];
    [searchNavController setViewControllers:@[[[ZBSearchViewController alloc] init]] animated:NO];
    [searchNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Search" image:[UIImage imageNamed:@"Search"] tag:3]];
    [searchNavController.navigationBar setPrefersLargeTitles:YES];
    
    self.viewControllers = @[homeNavController, sourcesNavController, packagesNavController, searchNavController];
    
    self->updates = [[PLPackageManager sharedInstance] updates].count;
    [self setPackageUpdateBadgeValue:self->updates];
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

- (void)showRefreshIndicator {
    [self setSourceRefreshIndicatorVisible:YES];
}

- (void)hideRefreshIndicator {
    [ZBSettings updateLastSourceUpdate];
    [self setSourceRefreshIndicatorVisible:NO];
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

- (void)updateQueue:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->queueCount = [notification.userInfo[@"count"] unsignedIntValue];
        [self updateQueueBar];
    });
}

- (void)updateUpdates:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->updates = [notification.userInfo[@"count"] unsignedIntValue];
        [self setPackageUpdateBadgeValue:self->updates];
    });
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
        [self updateQueueBarPackageCount];
        
        if (self->queueCount == 0) {
            [self closeQueue];
        } else {
            LNPopupPresentationState state = self.popupPresentationState;
            if (state != LNPopupPresentationStateOpen) {
                [self openQueue:NO];
            } else {
                [[self popupBar] setNeedsLayout];
            }
        }
    });
}

- (void)updateQueueBarPackageCount {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->queueCount > 0) {
            self.popupController.popupItem.title = self->queueCount > 1 ? [NSString stringWithFormat:NSLocalizedString(@"%lu Packages Queued", @""), (unsigned long)self->queueCount] : [NSString stringWithFormat:NSLocalizedString(@"%lu Package Queued", @""), (unsigned long)self->queueCount];
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
        if ((openPopup && state == LNPopupPresentationStateOpen) || (!openPopup && (state == LNPopupPresentationStateOpen || state == LNPopupPresentationStateBarPresented))) {
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

- (void)closeQueue {
    dispatch_async(dispatch_get_main_queue(), ^{
        LNPopupPresentationState state = self.popupPresentationState;
        if (state == LNPopupPresentationStateOpen || state == LNPopupPresentationStateBarPresented) {
            [self dismissPopupBarAnimated:YES completion:^{
                self.popupController = nil;
            }];
        }
    });
}

- (void)handleHoldGesture:(UILongPressGestureRecognizer *)gesture {
    if (UIGestureRecognizerStateBegan == gesture.state) {
        UIAlertController *clearQueue = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Clear Queue", @"") message:NSLocalizedString(@"Are you sure you want to clear the Queue?", @"") preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            [[PLQueue sharedInstance] clear];
        }];
        [clearQueue addAction:yesAction];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleCancel handler:nil];
        [clearQueue addAction:noAction];
        
        [self presentViewController:clearQueue animated:YES completion:nil];
    }
    
}

- (void)requestSourceRefresh {
    [self refreshSources:NO];
}

- (void)refreshSources:(BOOL)userRequested {
    BOOL needsUpdate = NO;
    if (!userRequested && [ZBSettings wantsAutoRefresh]) {
        NSDate *currentDate = [NSDate date];
        NSDate *lastUpdatedDate = [ZBSettings lastSourceUpdate];

        if (lastUpdatedDate != NULL) {
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags fromDate:lastUpdatedDate toDate:currentDate options:0];

            needsUpdate = ([components minute] >= 30);
        } else {
            needsUpdate = YES;
        }
    }
    
    if (userRequested || needsUpdate) {
        [[PLSourceManager sharedInstance] refreshSources];
    }
}

#pragma mark - Keyboard Shortcuts

- (NSArray<UIKeyCommand *> *)keyCommands {
    UIKeyCommand *home = [UIKeyCommand keyCommandWithInput:@"1" modifierFlags:UIKeyModifierCommand action:@selector(homeTab)];
    home.discoverabilityTitle = @"Switch to Home";

    UIKeyCommand *sources = [UIKeyCommand keyCommandWithInput:@"2" modifierFlags:UIKeyModifierCommand action:@selector(sourcesTab)];
    sources.discoverabilityTitle = @"Switch to Sources";

    UIKeyCommand *installed = [UIKeyCommand keyCommandWithInput:@"3" modifierFlags:UIKeyModifierCommand action:@selector(installedTab)];
    installed.discoverabilityTitle = @"Switch to Installed";

    UIKeyCommand *search = [UIKeyCommand keyCommandWithInput:@"4" modifierFlags:UIKeyModifierCommand action:@selector(searchTab)];
    search.discoverabilityTitle = @"Switch to Search";

    // escape key
    UIKeyCommand *back = [UIKeyCommand keyCommandWithInput:@"\e" modifierFlags:0 action:@selector(backShortcut)];
    back.discoverabilityTitle = NSLocalizedString(@"Back", @"");

    return @[home, sources, installed, search, back];
}

- (void)homeTab {
    self.selectedIndex = 0;
}

- (void)sourcesTab {
    self.selectedIndex = 1;
}

- (void)installedTab {
    self.selectedIndex = 2;
}

- (void)searchTab {
    self.selectedIndex = 3;
}

- (void)backShortcut {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
