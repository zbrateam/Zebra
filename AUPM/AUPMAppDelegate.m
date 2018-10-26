//
//  AUPMAppDelegate.m
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "AUPMAppDelegate.h"
#import "AUPMDatabaseManager.h"
#import "AUPMRefreshViewController.h"
#import "AUPMTabBarController.h"
//#import "NSTask.h"

@interface AUPMAppDelegate ()

@end

@implementation AUPMAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.tintColor = [UIColor colorWithRed:0.62 green:0.67 blue:0.90 alpha:1.0];
    
//    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
//
//    config.fileURL = [NSURL URLWithString:@"/var/lib/aupm/database/aupm.realm"];
//    config.deleteRealmIfMigrationNeeded = YES;
//    [RLMRealmConfiguration setDefaultConfiguration:config];
//
    self.databaseManager = [[AUPMDatabaseManager alloc] init];
    
//    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/aupm/aupm.list"]) {
//        NSTask *cpTask = [[NSTask alloc] init];
//        [cpTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
//        NSArray *cpArgs = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/default.list", @"/var/lib/aupm/aupm.list", nil];
//        [cpTask setArguments:cpArgs];
//
//        [cpTask launch];
//        [cpTask waitUntilExit];
//    }
    
//    NSError *configError;
    RLMRealm *realm = [RLMRealm defaultRealm];//realmWithConfiguration:config error:&configError];
    
//    if (configError != nil) {
//        NSLog(@"[AUPM] Error when opening database: %@", configError.localizedDescription);
//    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ([realm isEmpty]) {
        AUPMRefreshViewController *refreshViewController = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
        
        self.window.rootViewController = refreshViewController;
    }
    else {
        AUPMTabBarController *tabBarController = [storyboard instantiateViewControllerWithIdentifier:@"tabBarController"];
        
        self.window.rootViewController = tabBarController;
    }
    
    [self.window makeKeyAndVisible];
    
    return YES;
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
