//
//  ZBDarkModeHelper.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 14/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBDarkModeHelper.h"
#import <UIKit/UIKit.h>
#import <WebKit/WKWebView.h>
#import <UIColor+GlobalColors.h>

@implementation ZBDarkModeHelper

+ (BOOL)darkModeEnabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"darkMode"];
}

+ (void)setDarkModeEnabled:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:@"darkMode"];
    [defaults synchronize];
}

+ (void)configureDark {
    [[UINavigationBar appearance] setTintColor:[UIColor tintColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    if (@available(iOS 11.0, *)) {
        [[UINavigationBar appearance] setLargeTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    }
    else {
        
    }
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1]];
    [[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1]];
    [[UINavigationBar appearance] setTranslucent:TRUE];
    //Light Status bar
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    
    //Tab
    [[UITabBar appearance] setTintColor:[UIColor tintColor]];
    [[UITabBar appearance] setBackgroundColor:[UIColor colorWithRed:0.11 green:0.11 blue:0.11 alpha:1.0]];
    [[UITabBar appearance] setBarTintColor:[UIColor colorWithRed:0.11 green:0.11 blue:0.11 alpha:1.0]];
    [[UITabBar appearance] setBarStyle:UIBarStyleBlack];
    
    //Tables
    [[UITableView appearance] setBackgroundColor:[UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1.0]];
    [[UITableView appearance] setTintColor:[UIColor tintColor]];
    [[UITableViewCell appearance] setBackgroundColor:[UIColor colorWithRed:0.110 green:0.110 blue:0.114 alpha:1.0]];
    UIView *dark = [[UIView alloc] init];
    dark.backgroundColor = [UIColor selectedCellBackgroundColorDark];
    [[UITableViewCell appearance] setSelectedBackgroundView:dark];
    [UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class]]].textColor = [UIColor whiteColor];
    [[WKWebView appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [[WKWebView appearance] setOpaque:FALSE];
}

+ (void)configureLight {
    [[UINavigationBar appearance] setTintColor:[UIColor tintColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:nil];
    if (@available(iOS 11.0, *)) {
        [[UINavigationBar appearance] setLargeTitleTextAttributes:nil];
    }
    else {
        
    }
    [[UINavigationBar appearance] setBarTintColor:nil];
    [[UINavigationBar appearance] setBackgroundColor:nil];
    [[UINavigationBar appearance] setTranslucent:TRUE];
    //Light Status bar
    [[UINavigationBar appearance] setBarStyle:UIBarStyleDefault];
    
    //Tab
    [[UITabBar appearance] setTintColor:[UIColor tintColor]];
    [[UITabBar appearance] setBackgroundColor:nil];
    [[UITabBar appearance] setBarTintColor:nil];
    [[UITabBar appearance] setBarStyle:UIBarStyleDefault];
    
    //Tables
    [[UITableView appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [[UITableView appearance] setTintColor:nil];
    [[UITableViewCell appearance] setBackgroundColor:[UIColor cellBackgroundColor]];
    [UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class]]].textColor = [UIColor cellPrimaryTextColor];
    [[WKWebView appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [[WKWebView appearance] setOpaque:TRUE];
}

+ (void)applySettings {
    if ([self darkModeEnabled]) {
        [self configureDark];
    }
    else {
        [self configureLight];
    }
}

+ (void)refreshViews {
    //[[NSNotificationCenter defaultCenter] postNotificationName:UISSWillRefreshViewsNotification object:self];
    
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        for (UIView *view in window.subviews) {
            [view removeFromSuperview];
            [window addSubview:view];
        }
    }
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:UISSDidRefreshViewsNotification object:self];
}

@end
