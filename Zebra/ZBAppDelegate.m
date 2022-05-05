//
//  ZBAppDelegate.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBAppDelegate.h"
#import "ZBTabBarController.h"
#import "ZBLog.h"
#import "ZBTab.h"
#import "ZBDevice.h"
#import "ZBSettings.h"
#import <UserNotifications/UserNotifications.h>
#import "UIColor+GlobalColors.h"
#import "ZBSourceListTableViewController.h"
#import "ZBPackageDepictionViewController.h"
#import <SDWebImage/SDImageCacheConfig.h>
#import <SDWebImage/SDImageCache.h>
#import "ZBSource.h"
#import "ZBThemeManager.h"
#import "ZBRefreshViewController.h"
#import "ZBSearchTableViewController.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import "AccessibilityUtilities.h"
#import "ZBSafariAuthenticationSession.h"

#if __has_include("ZebraKeys.private.h")
#import "ZebraKeys.private.h"
#endif

@import Sentry;

@interface ZBAppDelegate () {
    NSString *forwardToPackageID;
    BOOL screenRecording;
}

@end

static const NSInteger kZebraMaxTime = 60 * 60 * 24; // 1 day

@implementation ZBAppDelegate

NSString *const ZBUserWillTakeScreenshotNotification = @"WillTakeScreenshotNotification";
NSString *const ZBUserDidTakeScreenshotNotification = @"DidTakeScreenshotNotification";

NSString *const ZBUserStartedScreenCaptureNotification = @"StartedScreenCaptureNotification";
NSString *const ZBUserEndedScreenCaptureNotification = @"EndedScreenCaptureNotification";

#pragma mark - Constants

+ (NSString *)bundleID {
    return [[NSBundle mainBundle] bundleIdentifier];
}

+ (NSString *)documentsDirectory {
    NSString *path_ = nil;
    if (![ZBDevice needsSimulation]) {
        path_ = @"/var/mobile/Library/Application Support";
    } else {
        path_ = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    }
    NSString *path = [path_ stringByAppendingPathComponent:[self bundleID]];
    BOOL dirExists = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dirExists];
    if (!dirExists) {
        ZBLog(@"[Zebra] Creating documents directory.");
        NSError *error = NULL;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error != NULL) {
            [self sendErrorToTabController:[NSString stringWithFormat:NSLocalizedString(@"Error while creating documents directory: %@.", @""), error.localizedDescription]];
            NSLog(@"[Zebra] Error while creating documents directory: %@.", error.localizedDescription);
        }
    }
    
    return path;
}

+ (NSURL *)documentsDirectoryURL {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"filza://view%@", [self documentsDirectory]] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
}

+ (NSString *)listsLocation {
    NSString *lists = [[self documentsDirectory] stringByAppendingPathComponent:@"/lists/"];
    BOOL dirExists = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:lists isDirectory:&dirExists];
    if (!dirExists) {
        ZBLog(@"[Zebra] Creating lists directory.");
        NSError *error = NULL;
        [[NSFileManager defaultManager] createDirectoryAtPath:lists withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error != NULL) {
            [self sendErrorToTabController:[NSString stringWithFormat:NSLocalizedString(@"Error while creating lists directory: %@.", @""), error.localizedDescription]];
            NSLog(@"[Zebra] Error while creating lists directory: %@.", error.localizedDescription);
        }
    }
    return lists;
}

+ (NSURL *)sourcesListURL {
    return [NSURL fileURLWithPath:[self sourcesListPath]];
}

+ (NSString *)sourcesListPath {
    NSString *lists = [[self documentsDirectory] stringByAppendingPathComponent:@"sources.list"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:lists]) {
        ZBLog(@"[Zebra] Creating sources.list.");
        NSError *error = NULL;
        [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"default" ofType:@"list"] toPath:lists error:&error];
        
        if (error != NULL) {
            [self sendErrorToTabController:[NSString stringWithFormat:NSLocalizedString(@"Error while creating sources.list: %@.", @""), error.localizedDescription]];
            NSLog(@"[Zebra] Error while creating sources.list: %@.", error.localizedDescription);
        }
    }
    return lists;
}

+ (NSString *)databaseLocation {
    return [[self documentsDirectory] stringByAppendingPathComponent:@"zebra.db"];
}

+ (NSString *)debsLocation {
    NSString *debs = [[self documentsDirectory] stringByAppendingPathComponent:@"/debs/"];
    BOOL dirExists = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:debs isDirectory:&dirExists];
    if (!dirExists) {
        ZBLog(@"[Zebra] Creating debs directory.");
        NSError *error = NULL;
        [[NSFileManager defaultManager] createDirectoryAtPath:debs withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error != NULL) {
            [self sendErrorToTabController:[NSString stringWithFormat:NSLocalizedString(@"Error while creating debs directory: %@.", @""), error.localizedDescription]];
            NSLog(@"[Zebra] Error while creating debs directory: %@.", error.localizedDescription);
        }
    }
    return debs;
}

+ (ZBTabBarController *)tabBarController {
    if ([NSThread isMainThread]) {
        return (ZBTabBarController *)((ZBAppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;
    }
    else {
        __block ZBTabBarController *tabController;
        dispatch_sync(dispatch_get_main_queue(), ^{
            tabController = (ZBTabBarController *)((ZBAppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;
        });
        return tabController;
    }
}

#pragma mark - Alerts

+ (void)sendAlertFrom:(UIViewController *)vc title:(NSString *)title message:(NSString *)message actionLabel:(NSString *)actionLabel okLabel:(NSString *)okLabel block:(void (^)(void))block {
    UIViewController *trueVC = vc ? vc : [self tabBarController];
    if (trueVC != NULL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            
            if (actionLabel != nil && block != NULL) {
                UIAlertAction *blockAction = [UIAlertAction actionWithTitle:actionLabel style:UIAlertActionStyleDefault handler:^(UIAlertAction *action_) {
                    block();
                }];
                [alert addAction:blockAction];
            }
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:okLabel style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:okAction];
            [trueVC presentViewController:alert animated:YES completion:nil];
        });
    }
}

+ (void)sendAlertFrom:(UIViewController *)vc message:(NSString *)message {
    [self sendAlertFrom:vc title:@"Zebra" message:message actionLabel:nil okLabel:NSLocalizedString(@"OK", @"") block:NULL];
}

+ (void)sendErrorToTabController:(NSString *)error actionLabel:(NSString *)actionLabel block:(void (^)(void))block {
    [self sendAlertFrom:nil title:NSLocalizedString(@"An Error Occurred", @"") message:error actionLabel:actionLabel okLabel:NSLocalizedString(@"Dismiss", @"") block:block];
}

+ (void)sendErrorToTabController:(NSString *)error {
    [self sendErrorToTabController:error actionLabel:nil block:NULL];
}

#pragma mark - App Delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self _configureErrorReporting];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:SendErrorReportsKey options:kNilOptions context:nil];

    setenv("PATH", [ZBDevice path].UTF8String, 1);

    NSString *documentsDirectory = [ZBAppDelegate documentsDirectory];
    NSLog(@"[Zebra] Documents Directory: %@", documentsDirectory);

    [SDImageCache sharedImageCache].config.maxDiskAge = kZebraMaxTime;
    
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (error) {
                NSLog(@"[Zebra] Error: %@", error.localizedDescription);
            } else if (!granted) {
                NSLog(@"[Zebra] Authorization was not granted.");
            } else {
                NSLog(@"[Zebra] Notification access granted.");
            }
        }];
    } else {
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge categories:nil]];            
        }
    }
    
    UIApplication.sharedApplication.delegate.window.tintColor = [UIColor accentColor];
    
    [[ZBThemeManager sharedInstance] updateInterfaceStyle];
    
    [self registerForScreenshotNotifications];
    
    self.window.tintColor = [UIColor accentColor];
    if ([ZBDatabaseManager needsMigration]) {
        NSURL *url = launchOptions[UIApplicationLaunchOptionsURLKey];
        if (url) {
            if ([[url scheme] isEqualToString:@"file"] && [[url pathExtension] isEqualToString:@"list"]) {
                NSString *listPath = [ZBAppDelegate sourcesListPath];
                
                NSError *removeError;
                if ([[NSFileManager defaultManager] fileExistsAtPath:listPath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:listPath error:&removeError];
                }
                
                if (!removeError) {
                    [[NSFileManager defaultManager] moveItemAtPath:[url path] toPath:listPath error:nil];
                }
            }
        }
        
        self.window.rootViewController = [[ZBRefreshViewController alloc] initWithDropTables:YES];
    }
    
    if (@available(iOS 11.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForScreenRecording:) name:UIScreenCapturedDidChangeNotification object:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForScreenRecording:) name:UIScreenDidConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForScreenRecording:) name:UIScreenDidDisconnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForScreenRecording:) name:UIScreenModeDidChangeNotification object:nil];
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    NSArray *choices = @[@"file", @"zbra", @"sileo"];
    int index = (int)[choices indexOfObject:[url scheme]];
    
    if (![self.window.rootViewController isKindOfClass:[ZBTabBarController class]]) {
        return NO;
    }
    
    switch (index) {
        case 0: { // file
            if ([[url pathExtension] isEqualToString:@"deb"]) {
                
                NSString *newLocation = [[[self class] debsLocation] stringByAppendingPathComponent:[url lastPathComponent]];
                
                NSError *moveError;
                [[NSFileManager defaultManager] moveItemAtPath:[url path] toPath:newLocation error:&moveError];
                if (moveError) {
                    NSLog(@"[Zebra] Couldn't move deb %@", moveError.localizedDescription);
                }
                else {
                    ZBPackage *package = [[ZBPackage alloc] initFromDeb:newLocation];
                    ZBPackageDepictionViewController *depicition = [[ZBPackageDepictionViewController alloc] initWithPackage:package];
                    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:depicition];
                    
                    [self.window.rootViewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
                    [self.window.rootViewController presentViewController:navController animated:YES completion:nil];
                    [[ZBDatabaseManager sharedInstance] setHaltDatabaseOperations:YES];
                }
            } else if ([[url pathExtension] isEqualToString:@"list"] || [[url pathExtension] isEqualToString:@"sources"]) {
                ZBTabBarController *tabController = (ZBTabBarController *)self.window.rootViewController;
                [tabController setSelectedIndex:ZBTabSources];
                    
                ZBSourceListTableViewController *sourceListController = (ZBSourceListTableViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
                [sourceListController handleImportOf:url];
            }
            break;
        }
        case 1: { // zbra
            ZBTabBarController *tabController = (ZBTabBarController *)self.window.rootViewController;
            
            NSArray *components = [[url host] componentsSeparatedByString:@"/"];
            choices = @[@"home", @"sources", @"changes", @"packages", @"search"];
            index = (int)[choices indexOfObject:components[0]];
            
            switch (index) {
                case 0: {
                    [tabController setSelectedIndex:ZBTabHome];
                    break;
                }
                case 1: {
                    [tabController setSelectedIndex:ZBTabSources];
                    
                    ZBSourceListTableViewController *sourceListController = (ZBSourceListTableViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
                    [sourceListController handleURL:url];
                    break;
                }
                case 2: {
                    [tabController setSelectedIndex:ZBTabChanges];
                    break;
                }
                case 3: {
                    NSString *path = [url path];
                    if (path.length > 1) {
                        NSString *sourceURL = [[url query] componentsSeparatedByString:@"source="][1];
                        if (sourceURL != NULL) {
                            if ([ZBSource exists:sourceURL]) {
                                NSString *packageID = [path substringFromIndex:1];
                                ZBSource *source = [ZBSource sourceFromBaseURL:sourceURL];
                                ZBPackage *package = [[ZBDatabaseManager sharedInstance] topVersionForPackageID:packageID inSource:source];
                                ZBPackageDepictionViewController *packageController = [[ZBPackageDepictionViewController alloc] initWithPackage:package];
                                if (packageController) {
                                    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:packageController];
                                    [tabController presentViewController:navController animated:YES completion:nil];
                                }
                                else {
                                    [ZBAppDelegate sendErrorToTabController:[NSString stringWithFormat:NSLocalizedString(@"Could not locate %@ from %@", @""), packageID, [source origin]]];
                                }
                            }
                            else {
                                NSString *packageID = [path substringFromIndex:1];
                                [tabController setForwardToPackageID:packageID];
                                [tabController setForwardedSourceBaseURL:sourceURL];
                                
                                NSURL *newURL = [NSURL URLWithString:[NSString stringWithFormat:@"zbra://sources/add/%@", sourceURL]];
                                [self application:application openURL:newURL options:options];
                            }
                        }
                        else {
                            NSString *packageID = [path substringFromIndex:1];
                            ZBPackage *package = [[ZBDatabaseManager sharedInstance] topVersionForPackageID:packageID];
                            ZBPackageDepictionViewController *packageController = [[ZBPackageDepictionViewController alloc] initWithPackage:package];
                            if (packageController) {
                                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:packageController];
                                [tabController presentViewController:navController animated:YES completion:nil];
                            }
                            else {
                                [ZBAppDelegate sendErrorToTabController:[NSString stringWithFormat:NSLocalizedString(@"Could not locate %@", @""), packageID]];
                            }
                        }
                    }
                    else {
                        [tabController setSelectedIndex:ZBTabPackages];
                    }
                    break;
                }
                case 4: {
                    [tabController setSelectedIndex:ZBTabSearch];
                    
                    ZBSearchTableViewController *searchController = (ZBSearchTableViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
                    [searchController handleURL:url];
                    break;
                }
            }
            break;
        }
        case 2: { // sileo
            // Forward to current Safari auth session, if any.
            [ZBSafariAuthenticationSession handleCallbackURL:url];
        }
        default: {
            return NO;
        }
    }
    
    return YES;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    if (![self.window.rootViewController isKindOfClass:[ZBTabBarController class]]) {
        return;
    }
    
    ZBTabBarController *tabController = (ZBTabBarController *)self.window.rootViewController;
    if ([shortcutItem.type isEqualToString:@"Search"]) {
        [tabController setSelectedIndex:ZBTabSearch];
        
        ZBSearchTableViewController *searchController = (ZBSearchTableViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
        [searchController handleURL:nil];
    } else if ([shortcutItem.type isEqualToString:@"Add"]) {
        [tabController setSelectedIndex:ZBTabSources];
        
        ZBSourceListTableViewController *sourceListController = (ZBSourceListTableViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
        [sourceListController handleURL:[NSURL URLWithString:@"zbra://sources/add"]]; 
    }
}

#pragma mark - Screenshot

- (void)registerForScreenshotNotifications {
    dlopen("/System/Library/PrivateFrameworks/AccessibilityUtilities.framework/AccessibilityUtilities", RTLD_NOW);
    AXSpringBoardServer *server = [objc_getClass("AXSpringBoardServer") server];
    [server registerSpringBoardActionHandler:^(int eventType) {
        if (eventType == 6) { // Before taking screenshot
            [[NSNotificationCenter defaultCenter] postNotificationName:ZBUserWillTakeScreenshotNotification object:nil];
        }
        else if (eventType == 7) { // After taking screenshot
            [[NSNotificationCenter defaultCenter] postNotificationName:ZBUserDidTakeScreenshotNotification object:nil];
        }
    } withIdentifierCallback:^(int a) {}];
}

- (void)checkForScreenRecording:(NSNotification *)notif {
    UIScreen *screen = [notif object];
    if (!screen) return;
    
    if (@available(iOS 11.0, *)) {
        if ([screen isCaptured] || [screen mirroredScreen]) {
            screenRecording = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:ZBUserStartedScreenCaptureNotification object:nil];
        }
        else if (screenRecording) {
            screenRecording = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:ZBUserEndedScreenCaptureNotification object:nil];
        }
    }
    else {
        if ([screen mirroredScreen]) {
            screenRecording = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:ZBUserStartedScreenCaptureNotification object:nil];
        }
        else if (screenRecording) {
            screenRecording = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:ZBUserEndedScreenCaptureNotification object:nil];
        }
    }
}

#pragma mark - Tab Bar Controller

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UINavigationController *)navigationController {
    static UITableViewController *previousController = nil;
    UITableViewController *currentController = [navigationController viewControllers][0];
    if (previousController == currentController) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wundeclared-selector"

        if ([currentController respondsToSelector:@selector(scrollToTop)]) {
            [currentController performSelector:@selector(scrollToTop)];
        }

        #pragma clang diagnostic pop
    }
    previousController = [navigationController viewControllers][0]; // Should set the previousController to the rootVC
}

#pragma mark - Error Reporting

- (void)_configureErrorReporting {
#if !defined(DEBUG) && defined(SENTRY_DSN)
    static SentryEvent *eventPendingReport = nil;
    [SentrySDK startWithConfigureOptions:^(SentryOptions *options) {
        options.dsn = SENTRY_DSN;
        options.beforeSend = ^SentryEvent * _Nullable (SentryEvent *event) {
            switch ([ZBSettings sendErrorReports]) {
            case ZBSendErrorReportsUnspecified:
                // Hold onto this event so we can send it if the user consents.
                eventPendingReport = event;
                return nil;
            case ZBSendErrorReportsNo:
                return nil;
            case ZBSendErrorReportsYes:
                return event;
            }
        };
    }];
    [SentrySDK configureScope:^(SentryScope *scope) {
        scope.tags = @{
            @"bootstrap": [ZBDevice bootstrapName],
            @"jailbreak": [ZBDevice jailbreakName],
            @"has_slingshot": @(![ZBDevice isSlingshotBroken:nil]),
            @"is_stashed": @([ZBDevice isStashed]),
        };
    }];

    if (eventPendingReport && [ZBSettings sendErrorReports] != ZBSendErrorReportsUnspecified) {
        // User has now responded to consent prompt. It’ll either be sent or discarded here.
        [SentrySDK captureEvent:eventPendingReport];
        eventPendingReport = nil;
    }
#endif
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:SendErrorReportsKey]) {
        [self _configureErrorReporting];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
