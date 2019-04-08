//
//  ZBAppDelegate.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBAppDelegate.h"

@interface ZBAppDelegate ()

@end

@implementation ZBAppDelegate

+ (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths[0];
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

+ (BOOL)listsExists {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self sourceListLocation]];
}

+ (NSString *)sourceListLocation {
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
