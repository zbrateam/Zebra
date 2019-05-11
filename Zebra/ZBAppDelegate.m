//
//  ZBAppDelegate.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBAppDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import <Packages/Controllers/ZBExternalPackageTableViewController.h>
#import <ZBTabBarController.h>
#import <UIColor+GlobalColors.h>
#import <Repos/Controllers/ZBRepoListTableViewController.h>

@interface ZBAppDelegate ()

@end

@implementation ZBAppDelegate

+ (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    if ([paths[0] isEqualToString:@"/var/mobile/Documents"]) {
        NSString *path = [paths[0] stringByAppendingPathComponent:@"xyz.willy.Zebra"];
        
        BOOL dirExsits;
        [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dirExsits];
        if (!dirExsits) {
            NSLog(@"[Zebra] Creating documents directory.");
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:&error];
            
            if (error != NULL) {
                NSLog(@"[Zebra] Error while creating documents directory: %@.", error.localizedDescription);
            }
        }
        
        return path;
    }
    else {
        return paths[0];
    }
}

+ (BOOL)needsSimulation {
    return ![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Zebra.app/supersling"];
}

+ (NSString *)listsLocation {
    NSString *lists = [[self documentsDirectory] stringByAppendingPathComponent:@"/lists/"];
    BOOL dirExsits;
    [[NSFileManager defaultManager] fileExistsAtPath:lists isDirectory:&dirExsits];
    if (!dirExsits) {
        NSLog(@"[Zebra] Creating lists directory.");
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:lists withIntermediateDirectories:true attributes:nil error:&error];
        
        if (error != NULL) {
            NSLog(@"[Zebra] Error while creating lists directory: %@.", error.localizedDescription);
        }
    }
    return lists;
}

+ (NSURL *)sourcesListURL {
    return [NSURL URLWithString:[@"file://" stringByAppendingString:[self sourcesListPath]]];
}

+ (NSString *)sourcesListPath {
    NSString *lists = [[self documentsDirectory] stringByAppendingPathComponent:@"sources.list"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:lists]) {
        NSLog(@"[Zebra] Creating sources.list.");
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"default" ofType:@"list"] toPath:lists error:&error];
        
        if (error != NULL) {
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
    BOOL dirExsits;
    [[NSFileManager defaultManager] fileExistsAtPath:debs isDirectory:&dirExsits];
    if (!dirExsits) {
        NSLog(@"[Zebra] Creating debs directory.");
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:debs withIntermediateDirectories:true attributes:nil error:&error];
        
        if (error != NULL) {
            NSLog(@"[Zebra] Error while creating debs directory: %@.", error.localizedDescription);
        }
    }
    return debs;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"[Zebra] Documents Directory: %@", [ZBAppDelegate documentsDirectory]);
    
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (error) {
                NSLog(@"[Zebra] Error: %@", error.localizedDescription);
            } else if (!granted) {
                NSLog(@"[Zebra] Authorization was not granted.");
            }
            else {
                NSLog(@"[Zebra] Notification access granted.");
            }
        }];
    } else {
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge categories:nil]];            
        }
    }
    
    UIApplication.sharedApplication.delegate.window.tintColor = [UIColor tintColor];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    NSArray *choices = @[@"file", @"zbra", @"cydia"];
    int index = (int)[choices indexOfObject:[url scheme]];
    
    switch (index) {
        case 0: { //file
            if ([[url pathExtension] isEqualToString:@"deb"]) {
                if (![ZBAppDelegate needsSimulation]) {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
                    UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"externalPackageController"];
                    
                    ZBExternalPackageTableViewController *external = vc.viewControllers[0];
                    external.fileURL = url;
                    
                    [self.window.rootViewController presentViewController:vc animated:true completion:nil];
                }
            }
            else if ([[url pathExtension] isEqualToString:@"list"]) {
                ZBTabBarController *tabController = (ZBTabBarController *)self.window.rootViewController;
                [tabController setSelectedIndex:1];
                
                ZBRepoListTableViewController *repoController = (ZBRepoListTableViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
                NSLog(@"[Zebra] %@", repoController);
                [repoController handleImportOf:url];
            }
            break;
        }
        case 1: { //zbra
            ZBTabBarController *tabController = (ZBTabBarController *)self.window.rootViewController;
            NSLog(@"%@", [url host]);
            NSArray *components = [[url host] componentsSeparatedByString:@"/"];
            choices = @[@"home", @"sources", @"packages", @"search"];
            index = (int)[choices indexOfObject:components[0]];
            
            switch (index) {
                case 0: {
                    [tabController setSelectedIndex:0];
                    break;
                }
                case 1: {
                    [tabController setSelectedIndex:1];
                    
                    ZBRepoListTableViewController *repoController = (ZBRepoListTableViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
                    [repoController handleURL:url];
                    break;
                }
                case 2: {
                    [tabController setSelectedIndex:2];
                    break;
                }
                case 3: {
                    [tabController setSelectedIndex:3];
                    break;
                }
            }
            break;
        }
        case 2: { //cydia
            ZBTabBarController *tabController = (ZBTabBarController *)self.window.rootViewController;
            NSLog(@"%@", [url host]);
            NSArray *components = [[url host] componentsSeparatedByString:@"/"];
            choices = @[@"home", @"sources", @"package", @"search"];
            index = (int)[choices indexOfObject:components[0]];
            
            switch (index) {
                case 0: {
                    [tabController setSelectedIndex:0];
                    break;
                }
                case 1: {
                    [tabController setSelectedIndex:1];
                    break;
                }
                case 2: {
                    [tabController setSelectedIndex:2];
                    break;
                }
                case 3: {
                    [tabController setSelectedIndex:3];
                    break;
                }
            }
            break;
        }
        default: { //WHO ARE YOU????
            return false;
        }
    }
    
    return true;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    // TODO: Make these actually work
    if ([shortcutItem.type isEqualToString:@"Search"]) {
        NSLog(@"Search Action Selected");
    }
    else if ([shortcutItem.type isEqualToString:@"Add"]) {
        NSLog(@"Add Repo Action Selected");
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

@end
