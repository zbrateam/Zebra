//
//  ZBAppDelegate.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBAppDelegate.h"
#import "ZBTabBarController.h"
#import <ZBTab.h>
#import <ZBDevice.h>
#import <ZBSettings.h>
#import <UserNotifications/UserNotifications.h>
#import <Packages/Controllers/ZBExternalPackageTableViewController.h>
#import <UIColor+GlobalColors.h>
#import <Repos/Controllers/ZBRepoListTableViewController.h>
#import <Search/ZBSearchViewController.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import <SDWebImage/SDImageCacheConfig.h>
#import <SDWebImage/SDImageCache.h>

@interface ZBAppDelegate ()

@end

static const NSInteger kZebraMaxTime = 60 * 60 * 24; // 1 day

@implementation ZBAppDelegate

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
        NSLog(@"[Zebra] Creating documents directory.");
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error != NULL) {
            [self sendErrorToTabController:[NSString stringWithFormat:@"Error while creating documents directory: %@.", error.localizedDescription]];
            NSLog(@"[Zebra] Error while creating documents directory: %@.", error.localizedDescription);
        }
    }
    
    return path;
}

+ (NSString *)listsLocation {
    NSString *lists = [[self documentsDirectory] stringByAppendingPathComponent:@"/lists/"];
    BOOL dirExists = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:lists isDirectory:&dirExists];
    if (!dirExists) {
        NSLog(@"[Zebra] Creating lists directory.");
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:lists withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error != NULL) {
            [self sendErrorToTabController:[NSString stringWithFormat:@"Error while creating lists directory: %@.", error.localizedDescription]];
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
        NSLog(@"[Zebra] Creating sources.list.");
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"default" ofType:@"list"] toPath:lists error:&error];
        
        if (error != NULL) {
            [self sendErrorToTabController:[NSString stringWithFormat:@"Error while creating sources.list: %@.", error.localizedDescription]];
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
        NSLog(@"[Zebra] Creating debs directory.");
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:debs withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error != NULL) {
            [self sendErrorToTabController:[NSString stringWithFormat:@"Error while creating debs directory: %@.", error.localizedDescription]];
            NSLog(@"[Zebra] Error while creating debs directory: %@.", error.localizedDescription);
        }
    }
    return debs;
}

+ (ZBTabBarController *)tabBarController {
    return (ZBTabBarController *)((ZBAppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;
}

+ (void)sendErrorToTabController:(NSString *)error blockAction:(NSString *)action block:(void (^)(void))block {
    ZBTabBarController *tabController = [self tabBarController];
    if (tabController != NULL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"An Error Occured" message:error preferredStyle:UIAlertControllerStyleAlert];
            
            if (action != nil && block != NULL) {
                UIAlertAction *blockAction = [UIAlertAction actionWithTitle:action style:UIAlertActionStyleDefault handler:^(UIAlertAction *action_) {
                    block();
                }];
                [errorAlert addAction:blockAction];
            }
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
            [errorAlert addAction:okAction];
            [tabController presentViewController:errorAlert animated:YES completion:nil];
        });
    }
}

+ (void)sendErrorToTabController:(NSString *)error {
    [self sendErrorToTabController:error blockAction:nil block:NULL];
}

- (void)setDefaultValues {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    if (![settings objectForKey:liveSearchKey]) {
        [settings setBool:YES forKey:liveSearchKey];
    }
    if (![settings objectForKey:wantsFeaturedKey]) {
        [settings setBool:YES forKey:wantsFeaturedKey];
    }
    if (![settings objectForKey:wantsNewsKey]) {
        [settings setBool:YES forKey:wantsNewsKey];
    }
    [settings synchronize];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSString *documentsDirectory = [ZBAppDelegate documentsDirectory];
    NSLog(@"[Zebra] Documents Directory: %@", documentsDirectory);
    
    [self setupSDWebImageCache];
    [ZBDevice applyThemeSettings];
    
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
    
    UIApplication.sharedApplication.delegate.window.tintColor = [UIColor tintColor];
    [self setDefaultValues];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    NSArray *choices = @[@"file", @"zbra", @"cydia", @"sileo"];
    int index = (int)[choices indexOfObject:[url scheme]];
    
    switch (index) {
        case 0: { // file
            if ([[url pathExtension] isEqualToString:@"deb"]) {
                if (![ZBDevice needsSimulation]) {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
                    UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"externalPackageController"];
                    
                    ZBExternalPackageTableViewController *external = vc.viewControllers[0];
                    external.fileURL = url;
                    
                    [self.window.rootViewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
                    [self.window.rootViewController presentViewController:vc animated:YES completion:nil];
                }
            } else if ([[url pathExtension] isEqualToString:@"list"] || [[url pathExtension] isEqualToString:@"sources"]) {
                ZBTabBarController *tabController = (ZBTabBarController *)self.window.rootViewController;
                [tabController setSelectedIndex:ZBTabSources];
                
                ZBRepoListTableViewController *repoController = (ZBRepoListTableViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
                [repoController handleImportOf:url];
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
                    
                    ZBRepoListTableViewController *repoController = (ZBRepoListTableViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
                    [repoController handleURL:url];
                    break;
                }
                case 2: {
                    [tabController setSelectedIndex:ZBTabChanges];
                    break;
                }
                case 3: {
                    NSString *path = [url path];
                    if (path.length > 1) {
                        NSString *packageID = [path substringFromIndex:1];
                        ZBPackageDepictionViewController *packageController = [[ZBPackageDepictionViewController alloc] initWithPackageID:packageID];
                        if (packageController) {
                            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:packageController];
                            [tabController presentViewController:navController animated:YES completion:nil];
                        }
                    } else {
                        [tabController setSelectedIndex:ZBTabPackages];
                    }
                    break;
                }
                case 4: {
                    [tabController setSelectedIndex:ZBTabSearch];
                    
                    ZBSearchViewController *searchController = (ZBSearchViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
                    [searchController handleURL:url];
                    break;
                }
            }
            break;
        }
        case 2: { // cydia
            ZBTabBarController *tabController = (ZBTabBarController *)self.window.rootViewController;
            NSArray *components = [[url host] componentsSeparatedByString:@"/"];
            choices = @[@"home", @"sources", @"changes", @"installed", @"package", @"search", @"url"];
            index = (int)[choices indexOfObject:components[0]];
            
            switch (index) {
                case 0 ... 3: {
                    [tabController setSelectedIndex:index];
                    break;
                }
                case 4: {
                    NSString *path = [url path];
                    if (path.length > 1) {
                        NSString *packageID = [path substringFromIndex:1];
                        ZBPackageDepictionViewController *packageController = [[ZBPackageDepictionViewController alloc] initWithPackageID:packageID];
                        if (packageController) {
                            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:packageController];
                            [tabController presentViewController:navController animated:YES completion:nil];
                        }
                    }
                    break;
                }
                case 5: {
                    [tabController setSelectedIndex:ZBTabSearch];
                    
                    ZBSearchViewController *searchController = (ZBSearchViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
                    [searchController handleURL:url];
                    break;
                }
                case 6: {
                    NSArray *components = [[url absoluteString] componentsSeparatedByString:@"share#?source="];
                    if ([components count] == 2) {
                        NSString *sourceURL = [components[1] componentsSeparatedByString:@"&package"][0];
                        [tabController setSelectedIndex:ZBTabSources];
                        
                        ZBRepoListTableViewController *repoController = (ZBRepoListTableViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
                        
                        NSURL *url = [NSURL URLWithString:[@"zbra://sources/add/" stringByAppendingString:sourceURL]];
                        [repoController handleURL:url];
                    }
                    break;
                }
            }
            break;
        }
        case 3: { // sileo
            NSString *sourceApplication = [options objectForKey:@"UIApplicationOpenURLOptionsSourceApplicationKey"];
            if ([sourceApplication isEqualToString:@"com.apple.SafariViewService"]) {
                NSArray *components = [[url host] componentsSeparatedByString:@"/"];
                choices = @[@"authentication_success", @"payment_completed"];
                index = (int)[choices indexOfObject:components[0]];
                switch (index) {
                    case 0: { // Authenticated
                        NSDictionary *data = [NSDictionary dictionaryWithObject:url forKey:@"callBack"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"AuthenticationCallBack" object:self userInfo:data];
                        break;
                    }
                    case 1: { // Purchase
                        // Reading their documentation, a callback may not be required here. I will leave this case switch for future use however, in case I am proven wrong.
                        break;
                    }
                }
                
            }
            break;
            
        }
        default: { // WHO ARE YOU????
            return NO;
        }
    }
    
    return YES;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    ZBTabBarController *tabController = (ZBTabBarController *)self.window.rootViewController;
    if ([shortcutItem.type isEqualToString:@"Search"]) {
        [tabController setSelectedIndex:ZBTabSearch];
        
        ZBSearchViewController *searchController = (ZBSearchViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
        [searchController handleURL:NULL];
    } else if ([shortcutItem.type isEqualToString:@"Add"]) {
        [tabController setSelectedIndex:ZBTabSources];
        
        ZBRepoListTableViewController *repoController = (ZBRepoListTableViewController *)((UINavigationController *)[tabController selectedViewController]).viewControllers[0];
        [repoController handleURL:[NSURL URLWithString:@"zbra://sources/add"]]; 
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

@end
