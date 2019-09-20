//
//  ZBAppDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Tabs/ZBTabBarController.h>

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface ZBAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
+ (NSString *)bundleID;
+ (NSString *)documentsDirectory;
+ (NSString *)cacheDirectory;
+ (NSString *)listsLocation;
+ (NSURL *)sourcesListURL;
+ (NSString *)sourcesListPath;
+ (NSString *)databaseLocation;
+ (NSString *)debsLocation;
+ (void)sendErrorToTabController:(NSString *)error;
+ (ZBTabBarController *)tabBarController;
@end

