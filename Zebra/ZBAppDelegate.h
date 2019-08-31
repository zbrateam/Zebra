//
//  ZBAppDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Tabs/ZBTabBarController.h>

@interface ZBAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
+ (NSString *)bundleID;
+ (NSString *)documentsDirectory;
+ (NSString *)listsLocation;
+ (NSURL *)sourcesListURL;
+ (NSString *)sourcesListPath;
+ (NSString *)databaseLocation;
+ (NSString *)debsLocation;
+ (void)sendErrorToTabController:(NSString *)error;
+ (ZBTabBarController *)tabBarController;
@end

