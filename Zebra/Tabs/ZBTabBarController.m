//
//  ZBTabBarController.m
//  Zebra
//
//  Created by Wilson Styres on 3/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBTabBarController.h"
#import "ZBDatabaseManager.h"
#import "ZBPackageListTableViewController.h"
#import "ZBSourceListTableViewController.h"
#import "ZBPackage.h"
#import "ZBAppDelegate.h"
#import "UITabBarItem.h"
#import "ZBRefreshViewController.h"
#import "UIColor+GlobalColors.h"
#import "ZBQueue.h"
#import "ZBTab.h"
#import "ZBQueueViewController.h"
#import "ZBDevice.h"
#import "UIAlertController+Private.h"
#import "ZBLabelTextView.h"
#import "ZBSettingsErrorReportingViewController.h"
#import "ZBQueueTabAccessoryView.h"

#if SENTRY
@import Sentry;
#endif

@import LNPopupController;

@interface ZBTabBarController () <UIAdaptivePresentationControllerDelegate> {
    NSMutableArray *errorMessages;
    ZBDatabaseManager *databaseManager;
    UIActivityIndicatorView *indicator;
#ifdef __IPHONE_26_0
    ZBQueueTabAccessoryView *_queueAccessoryView;
#endif
    BOOL sourcesUpdating;
    BOOL _queueBarVisible;
    BOOL _queueSheetVisible;
}

@property (nonatomic) UINavigationController *popupController;
@property (nonatomic, readonly) ZBQueueViewController *queueController;

@end

@implementation ZBTabBarController
@synthesize queueController = _queueController;
@synthesize popupController = _popupController;

@synthesize forwardedSourceBaseURL;
@synthesize forwardToPackageID;
@synthesize sourceBusyList;

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [super init];
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
    
    self.delegate = (ZBAppDelegate *)[[UIApplication sharedApplication] delegate];
    self->indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
    CGRect indicatorFrame = self->indicator.frame;
    self->indicator.frame = indicatorFrame;
    self->indicator.color = [UIColor whiteColor];

    NSInteger badgeValue = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    [self setPackageUpdateBadgeValue:badgeValue];
    [self updatePackagesTableView];
    
    databaseManager = [ZBDatabaseManager sharedInstance];
    if (![databaseManager needsToPresentRefresh]) {
        [databaseManager addDatabaseDelegate:self];
        [databaseManager updateDatabaseUsingCaching:YES userRequested:NO];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateQueueBar) name:@"ZBUpdateQueueBar" object:nil];
    
    NSError *error = NULL;
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
#if SENTRY
    } else if ([ZBSettings sendErrorReports] == ZBSendErrorReportsUnspecified && [SentrySDK crashedLastRun]) {
        [self _showErrorReportPrompt];
#endif
    }
    
    //poor hack to get the tab bar to re-layout
    if (@available(iOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, 1, 0);
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    }
}

- (void)setPackageUpdateBadgeValue:(NSInteger)updates {
    [self updatePackagesTableView];
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

- (void)updatePackagesTableView {
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *navController = self.viewControllers[ZBTabPackages];
        ZBPackageListTableViewController *packagesController = navController.viewControllers[0];
        [packagesController refreshTable];
    });
}

- (void)setSourceRefreshIndicatorVisible:(BOOL)visible {
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *sourcesController = self.viewControllers[ZBTabSources];
        UITabBarItem *sourcesItem = [sourcesController tabBarItem];
        [sourcesItem setAnimatedBadge:visible];
        if (visible) {
            if (self->sourcesUpdating) {
                return;
            }
            sourcesItem.badgeValue = @"";

            if (@available(iOS 26, *)) {
                // TODO: Broken on iOS 26
            } else {
                UIView *badge = [[sourcesItem view] valueForKey:@"_badge"];
                self->indicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
                self->indicator.center = badge.center;
                [self->indicator startAnimating];
                [badge addSubview:self->indicator];
            }
            self->sourcesUpdating = YES;
        } else {
            sourcesItem.badgeValue = nil;
            self->sourcesUpdating = NO;
        }
        [self clearSources];
    });
}

#pragma mark - Database Delegate

- (void)setSource:(NSString *)bfn busy:(BOOL)busy {
    if (bfn == NULL) return;
    if (!sourceBusyList) sourceBusyList = [NSMutableDictionary new];
    [sourceBusyList setObject:@(busy) forKey:bfn];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ZBSourceListTableViewController *sourcesVC = (ZBSourceListTableViewController *)((UINavigationController *)self.viewControllers[ZBTabSources]).viewControllers[0];
        [sourcesVC setSpinnerVisible:busy forSource:bfn];
    });
}

- (void)clearSources {
    [sourceBusyList removeAllObjects];
}

- (void)databaseStartedUpdate {
    [self setSourceRefreshIndicatorVisible:YES];
}

- (void)databaseCompletedUpdate:(NSInteger)packageUpdates {
    if (packageUpdates != -1) {
        [self setPackageUpdateBadgeValue:packageUpdates];
    }
    [self setSourceRefreshIndicatorVisible:NO];
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
        if (forwardedSourceBaseURL != NULL) {
            urlString = [urlString stringByAppendingFormat:@"?source=%@", forwardedSourceBaseURL];
            forwardedSourceBaseURL = NULL;
        }
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        forwardToPackageID = NULL;
    }
}

#pragma mark - Queue Popup Bar

- (UINavigationController *)popupController {
    if (!_popupController) {
        _popupController = [[UINavigationController alloc] initWithRootViewController:self.queueController];
        if (@available(iOS 15, *)) {
            UISheetPresentationController *sheetPresentation = _popupController.sheetPresentationController;
            sheetPresentation.detents = @[[UISheetPresentationControllerDetent mediumDetent]];
        }
        [self _applyQueueSheetTransition:_popupController];
    }
    return _popupController;
}

- (UIView *)queueBarSourceView {
#ifdef __IPHONE_26_0
    if (@available(iOS 26, *)) {
        return _queueAccessoryView;
    }
#endif
    return _queueBarVisible ? self.popupBar : nil;
}

- (void)_applyQueueSheetTransition:(UIViewController *)viewController {
#ifdef __IPHONE_18_0
    if (@available(iOS 18, *)) {
        __weak __typeof(self) weakSelf = self;
        viewController.preferredTransition = [UIViewControllerTransition zoomWithOptions:nil sourceViewProvider:^UIView *(__unused UIZoomTransitionSourceViewProviderContext *context) {
            return [weakSelf queueBarSourceView];
        }];
    }
#endif
}

- (ZBQueueViewController *)queueController {
    if (!_queueController) {
        _queueController = [ZBQueueViewController new];
    }

    return _queueController;
}

- (CGFloat)queueBarHeight {
    if (!_queueBarVisible) {
        return 0;
    }

#ifdef __IPHONE_26_0
    if (@available(iOS 26, *)) {
        return self.bottomAccessory.contentView.frame.size.height;
    }
#endif

    return self.popupBar.frame.size.height;
}

- (void)updateQueueBar {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger count = [ZBQueue count];
        [self updateQueueBarPackageCount:count];

        if (count == 0) {
            return;
        }

#ifdef __IPHONE_26_0
        if (@available(iOS 26, *)) {
            if (!self->_queueBarVisible) {
                [self openQueue:NO];
            }
        } else
#endif
        {
            LNPopupPresentationState state = self.popupPresentationState;
            if (state != LNPopupPresentationStateOpen) {
                [self openQueue:NO];
            } else {
                [[self popupBar] setNeedsLayout];
            }
        }
    });
}

- (void)updateQueueBarPackageCount:(NSUInteger)count {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title = nil, *subtitle = nil;

        if (count > 0) {
            title = count > 1
                ? [NSString stringWithFormat:NSLocalizedString(@"%d Packages Queued", @""), (int)count]
                : [NSString stringWithFormat:NSLocalizedString(@"%d Package Queued", @""), (int)count];
            subtitle = NSLocalizedString(@"Tap to manage", @"");
        } else {
            title = NSLocalizedString(@"No Packages Queued", @"");
            subtitle = nil;
        }

#ifdef __IPHONE_26_0
        if (@available(iOS 26, *)) {
            self->_queueAccessoryView.titleLabel.text = title;
            return;
        }
#endif

        self.popupContentViewController.popupItem.title = title;
        self.popupContentViewController.popupItem.subtitle = subtitle;

        [self->_queueController refreshTable];
    });
}

- (void)openQueue:(BOOL)openPopup {
    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef __IPHONE_26_0
        if (@available(iOS 26, *)) {
            if (openPopup && !self->_queueSheetVisible) {
                self->_queueSheetVisible = YES;
                UINavigationController *sheet = self.popupController;
                [self presentViewController:sheet animated:YES completion:nil];
                sheet.presentationController.delegate = self;
            }

            if (self->_queueBarVisible) {
                return;
            }

            self->_queueAccessoryView = [[ZBQueueTabAccessoryView alloc] init];
            UITabAccessory *accessory = [[UITabAccessory alloc] initWithContentView:self->_queueAccessoryView];
            [self setBottomAccessory:accessory animated:YES];

            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
            [self->_queueAccessoryView addGestureRecognizer:tapGesture];

            UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHoldGesture:)];
            longPressGesture.minimumPressDuration = 1;
            longPressGesture.delegate = self;
            [self->_queueAccessoryView addGestureRecognizer:longPressGesture];

            [self updateQueueBarPackageCount:[ZBQueue count]];
            self->_queueBarVisible = YES;
            return;
        }
#endif

        if (@available(iOS 15, *)) {
            if (openPopup && !self->_queueSheetVisible) {
                self->_queueSheetVisible = YES;
                UINavigationController *sheet = self.popupController;
                [self presentViewController:sheet animated:YES completion:nil];
                sheet.presentationController.delegate = self;
            }

            LNPopupPresentationState state = self.popupPresentationState;
            if (state == LNPopupPresentationStateOpen || state == LNPopupPresentationStateBarPresented) {
                return;
            }

            self.popupInteractionStyle = LNPopupInteractionStyleNone;
            self.popupContentView.popupCloseButtonStyle = LNPopupCloseButtonStyleNone;

            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
            [self.popupBar addGestureRecognizer:tapGestureRecognizer];

            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHoldGesture:)];
            longPress.minimumPressDuration = 1;
            longPress.delegate = self;
            [self.popupBar addGestureRecognizer:longPress];

            [self updateQueueBarPackageCount:[ZBQueue count]];

            [self presentPopupBarWithContentViewController:[[UIViewController alloc] init] openPopup:NO animated:YES completion:^{
                self->_queueBarVisible = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBQueueBarHeightDidChange" object:nil];
            }];
            return;
        }

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

        [self updateQueueBarPackageCount:[ZBQueue count]];

        [self presentPopupBarWithContentViewController:self.popupController openPopup:openPopup animated:YES completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBQueueBarHeightDidChange" object:nil];
        }];
    });
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self openQueue:YES];
    }
}

- (void)handleHoldGesture:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIAlertController *clearQueue = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
#ifdef __IPHONE_26_0
        clearQueue.popoverPresentationController.sourceView = _queueAccessoryView ?: self.popupContentView;
#else
        clearQueue.popoverPresentationController.sourceView = self.popupContentView;
#endif

        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Clear Queue", @"") style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
            [[ZBQueue sharedQueue] clear];
        }];
        [clearQueue addAction:yesAction];

        UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];
        [clearQueue addAction:noAction];

        [self presentViewController:clearQueue animated:YES completion:nil];
    }
}

- (void)_dismissQueueSheet {
    if (_queueSheetVisible) {
        _queueSheetVisible = NO;
        [_popupController dismissViewControllerAnimated:YES completion:nil];
        _popupController = nil;
        _queueController = nil;
    }
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    _queueSheetVisible = NO;
    _popupController = nil;
    _queueController = nil;
}

- (void)dismissQueue {
    if (@available(iOS 15, *)) {
        [self _dismissQueueSheet];
        return;
    }
    [self closePopupAnimated:YES completion:nil];
}

- (void)closeQueue {
    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef __IPHONE_26_0
        if (@available(iOS 26, *)) {
            if (!self->_queueBarVisible) {
                return;
            }

            [self setBottomAccessory:nil animated:YES];
            self->_queueBarVisible = NO;
            [self _dismissQueueSheet];

            [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBUpdateNavigationButtons" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBQueueBarHeightDidChange" object:nil];
            return;
        }
#endif

        if (@available(iOS 15, *)) {
            [self _dismissQueueSheet];
        }

        self->_queueBarVisible = NO;

        LNPopupPresentationState state = self.popupPresentationState;
        if (state == LNPopupPresentationStateOpen || state == LNPopupPresentationStateBarPresented) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
            [self dismissPopupBarAnimated:YES completion:^{
                self.popupController = nil;
                self->_queueController = nil;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBUpdateNavigationButtons" object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBQueueBarHeightDidChange" object:nil];
            }];
        }
    });
}

#pragma mark - Crash reporting

- (void)_showErrorReportPrompt {
    // Ask for consent to send this and future crash reports.
    NSString *title = NSLocalizedString(@"Sorry that Zebra crashed.", @"");
    NSString *message = NSLocalizedString(@"Would you like to send this and all future error reports to the Zebra Team? Reports are anonymous and provide technical details of what led to the error.", @"");
    NSString *linkText = NSLocalizedString(@"About Error Reporting & Privacy…", @"");

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Don’t Send", @"")
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(__unused UIAlertAction *action) {
        ZBSettings.sendErrorReports = @(ZBSendErrorReportsNo);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Send", @"")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(__unused UIAlertAction *action) {
        ZBSettings.sendErrorReports = @(ZBSendErrorReportsYes);
    }]];

    alertController.contentViewController = [[UIViewController alloc] init];

    UIView *contentView = alertController.contentViewController.view;
    contentView.translatesAutoresizingMaskIntoConstraints = NO;

    UIFont *font = [UIFont preferredFontForTextStyle:@"UICTFontTextStyleShortFootnote"];
    ZBLabelTextView *textView = [[ZBLabelTextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.textContainerInset = UIEdgeInsetsMake(round(font.ascender - font.lineHeight), 15, 18, 15);

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", message, linkText] attributes:@{
        NSForegroundColorAttributeName: [UIColor primaryTextColor],
        NSFontAttributeName: font,
        NSParagraphStyleAttributeName: paragraphStyle
    }];
    [attributedString addAttribute:NSLinkAttributeName
                             value:[NSURL URLWithString:@"zbra:"]
                             range:NSMakeRange(attributedString.string.length - linkText.length, linkText.length)];
    textView.attributedText = attributedString;
    textView.linkHandler = ^(__unused NSURL *url) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self _showErrorReportMoreInfo];
        }];
    };
    [contentView addSubview:textView];
    [NSLayoutConstraint activateConstraints:@[
        [textView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [textView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
        [textView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [textView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor]
    ]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)_showErrorReportMoreInfo {
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[ZBSettingsErrorReportingViewController alloc] init]];
    [self presentViewController:navigationController animated:YES completion:nil];
}

@end
