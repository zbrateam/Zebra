//
//  ZBAppDelegate.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#define IMAGE_CACHE_MAX_TIME 60 * 60 * 24 // 1 Day

#import "ZBAppDelegate.h"

#import "ZBTabBarController.h"

#import <Plains/Plains.h>

#import "ZBLog.h"
#import "ZBTab.h"
#import "Zebra-Swift.h"
#import "ZBNotificationManager.h"
#import "ZBSourceListViewController.h"
#import "ZBPackageViewController.h"
#import "ZBSearchViewController.h"
#import "ZBSourceViewController.h"
#import "ZBSourceImportViewController.h"
#import "ZBSidebarController.h"
#import <dlfcn.h>
#include <sys/stat.h>
//#import <objc/runtime.h>
#import "AccessibilityUtilities.h"

#import <SDWebImage/SDWebImage.h>

@interface ZBAppDelegate () {
    NSString *forwardToPackageID;
    BOOL screenRecording;
    PLConfig *config;
}

@property () UIBackgroundTaskIdentifier backgroundTask;

@end

@implementation ZBAppDelegate

NSString *const ZBUserWillTakeScreenshotNotification = @"WillTakeScreenshotNotification";
NSString *const ZBUserDidTakeScreenshotNotification = @"DidTakeScreenshotNotification";

NSString *const ZBUserStartedScreenCaptureNotification = @"StartedScreenCaptureNotification";
NSString *const ZBUserEndedScreenCaptureNotification = @"EndedScreenCaptureNotification";

- (void)handleSourceImport:(NSURL *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        ZBSourceImportViewController *importVC = [[ZBSourceImportViewController alloc] initWithPaths:@[url]];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:importVC];
        
        [self.window.rootViewController presentViewController:nav animated:YES completion:nil];
    });
}

- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    NSArray *choices = @[@"file", @"zbra"];
    int index = (int)[choices indexOfObject:[url scheme]];

//    if (![self.window.rootViewController isKindOfClass:[ZBTabBarController class]]) {
//        return NO;
//    }

    switch (index) {
        case 0: { // file
            if ([[url pathExtension] isEqualToString:@"deb"]) {
                [[PLQueue sharedInstance] queueLocalPackage:url];
            }
            
            if ([[url pathExtension] isEqualToString:@"list"] || [[url pathExtension] isEqualToString:@"sources"]) {
                [self handleSourceImport:url];
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

//                    ZBSourceListViewController *sourceListController = (ZBSourceListViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];

//                    [sourceListController handleURL:url];
                    break;
                }
                case 2: {
//                    [tabController setSelectedIndex:ZBTabChanges];
                    break;
                }
//                case 3: {
//                    NSString *path = [url path];
//                    if (path.length > 1) {
//                        NSString *sourceURL = [[url query] componentsSeparatedByString:@"source="][1];
//                        if (sourceURL != NULL) {
//                            if ([ZBSource exists:sourceURL]) {
//                                NSString *packageID = [path substringFromIndex:1];
//                                ZBSource *source = [ZBSource sourceFromBaseURL:sourceURL];
//                                ZBPackage *package = [[ZBDatabaseManager sharedInstance] topVersionForPackageID:packageID inSource:source];
//
//                                if (package) {
//                                    ZBPackageViewController *packageController = [[ZBPackageViewController alloc] initWithPackage:package];
//                                    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:packageController];
//                                    [tabController presentViewController:navController animated:YES completion:nil];
//                                }
//                                else {
//                                    [ZBAppDelegate sendErrorToTabController:[NSString stringWithFormat:NSLocalizedString(@"Could not locate %@ from %@", @""), packageID, [source origin]]];
//                                }
//                            }
//                            else {
//                                NSString *packageID = [path substringFromIndex:1];
//                                [tabController setForwardToPackageID:packageID];
//                                [tabController setForwardedSourceBaseURL:sourceURL];
//
//                                NSURL *newURL = [NSURL URLWithString:[NSString stringWithFormat:@"zbra://sources/add/%@", sourceURL]];
//                                [self application:application openURL:newURL options:options];
//                            }
//                        }
//                        else {
//                            NSString *packageID = [path substringFromIndex:1];
//                            ZBPackage *package = [[ZBDatabaseManager sharedInstance] topVersionForPackageID:packageID];
//                            if (package) {
//                                ZBPackageViewController *packageController = [[ZBPackageViewController alloc] initWithPackage:package];
//                                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:packageController];
//                                [tabController presentViewController:navController animated:YES completion:nil];
//                            }
//                            else {
//                                [ZBAppDelegate sendErrorToTabController:[NSString stringWithFormat:NSLocalizedString(@"Could not locate %@", @""), packageID]];
//                            }
//                        }
//                    }
//                    else {
//                        [tabController setSelectedIndex:ZBTabPackages];
//                    }
//                    break;
//                }
                case 4: {
                    [tabController setSelectedIndex:ZBTabSearch];

                    ZBSearchViewController *searchController = (ZBSearchViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
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
    if (![self.window.rootViewController isKindOfClass:[ZBTabBarController class]]) {
        return;
    }
    
    ZBTabBarController *tabController = (ZBTabBarController *)self.window.rootViewController;
    if ([shortcutItem.type isEqualToString:@"Search"]) {
        [tabController setSelectedIndex:ZBTabSearch];
        
        ZBSearchViewController *searchController = (ZBSearchViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
        [searchController handleURL:nil];
    } else if ([shortcutItem.type isEqualToString:@"Add"]) {
        [tabController setSelectedIndex:ZBTabSources];
        
//        ZBSourceListViewController *sourceListController = (ZBSourceListViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
        
//        [sourceListController handleURL:[NSURL URLWithString:@"zbra://sources/add"]];
    } else if ([shortcutItem.type isEqualToString:@"Refresh"]) {
//        ZBTabBarController *tabController = [ZBAppDelegate tabBarController];
//        
//        [tabController refreshSources:YES];
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(BackgroundCompletionHandler)completionHandler {
    NSDate *fetchStart = [NSDate date];
    NSLog(@"[Zebra] Background fetch started");

    self.backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"[Zebra] WARNING: Background refresh timed out");
        [application endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
        completionHandler(UIBackgroundFetchResultFailed);
    }];

//    [[ZBNotificationManager sharedInstance] performBackgroundFetch:^(UIBackgroundFetchResult result) {
//        NSTimeInterval fetchDuration = [[NSDate date] timeIntervalSinceDate:fetchStart];
//        NSLog(@"[Zebra] Background refresh finished in %f seconds", fetchDuration);
//        [application endBackgroundTask:self.backgroundTask];
//        self.backgroundTask = UIBackgroundTaskInvalid;
//        
//        // Hard-coded "NewData" for (hopefully) better fetch intervals
//        completionHandler(UIBackgroundFetchResultNewData);
//    }];
}

@end
