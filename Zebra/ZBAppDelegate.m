//
//  ZBAppDelegate.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBAppDelegate.h"
#import "ZBTabBarController.h"
#import <ZBLog.h>
#import <ZBTab.h>
#import <ZBDevice.h>
#import <ZBSettings.h>
#import <UserNotifications/UserNotifications.h>
#import <UIColor+GlobalColors.h>
#import <Sources/Controllers/ZBSourceListTableViewController.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import <SDImageCacheConfig.h>
#import <SDImageCache.h>
#import <Tabs/Sources/Helpers/ZBSource.h>
#import <Theme/ZBThemeManager.h>
#import <Database/ZBRefreshViewController.h>
#import <Search/ZBSearchTableViewController.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <Headers/AccessibilityUtilities.h>

@import FirebaseCore;
@import FirebaseAnalytics;
@import FirebaseCrashlytics;
@import LocalAuthentication;

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
    [self sendAlertFrom:vc title:@"Zebra" message:message actionLabel:nil okLabel:NSLocalizedString(@"Ok", @"") block:NULL];
}

+ (void)sendErrorToTabController:(NSString *)error actionLabel:(NSString *)actionLabel block:(void (^)(void))block {
    [self sendAlertFrom:nil title:NSLocalizedString(@"An Error Occurred", @"") message:error actionLabel:actionLabel okLabel:NSLocalizedString(@"Dismiss", @"") block:block];
}

+ (void)sendErrorToTabController:(NSString *)error {
    [self sendErrorToTabController:error actionLabel:nil block:NULL];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSString *documentsDirectory = [ZBAppDelegate documentsDirectory];
    NSLog(@"[Zebra] Documents Directory: %@", documentsDirectory);
    
    [self setupSDWebImageCache];
    
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
    
#if DEBUG
    NSLog(@"[Zebra] Crash Reporting and Analytics Disabled");
#else
    NSLog(@"[Zebra] Crash Reporting and Analytics Enabled");
    [FIRApp configure];
#endif
    
    [[FIRCrashlytics crashlytics] setCustomValue:PACKAGE_VERSION forKey:@"zebra_version"];
    
    NSString *jailbreak = @"Unknown (Older Jailbreak for < 11.0)";
    if ([ZBDevice isMystery]) {
        jailbreak = @"Mystery";
    }
    else if ([ZBDevice isCheckrain]) {
        jailbreak = @"checkra1n";
    }
    else if ([ZBDevice isChimera]) {
        jailbreak = @"Chimera";
    }
    else if ([ZBDevice isElectra]) {
        jailbreak = @"Electra";
    }
    else if ([ZBDevice isUncover]) {
        jailbreak = @"unc0ver";
    }
    
    [FIRAnalytics setUserPropertyString:jailbreak forName:@"Jailbreak"];
    [[FIRCrashlytics crashlytics] setCustomValue:jailbreak forKey:@"jailbreak_type"];
    [[FIRCrashlytics crashlytics] setCustomValue:[ZBDevice packageManagementBinary] forKey:@"package_binary"];
    
    [[ZBThemeManager sharedInstance] updateInterfaceStyle];
    
    [self registerForScreenshotNotifications];
    
    self.window.tintColor = [UIColor accentColor];
    if ([ZBDatabaseManager needsMigration]) {
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
    NSArray *choices = @[@"file", @"zbra"];
    int index = (int)[choices indexOfObject:[url scheme]];
    
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
        default: {
            return NO;
        }
    }
    
    return YES;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
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

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)setupSDWebImageCache {
    [SDImageCache sharedImageCache].config.maxDiskAge = kZebraMaxTime;
}

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

@end
