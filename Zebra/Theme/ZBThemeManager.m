//
//  ZBThemeManager.m
//  Zebra
//
//  Created by Wilson Styres on 1/15/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBThemeManager.h"
#import "UIColor+GlobalColors.h"
#import <UIKit/UIKit.h>

@import LNPopupController;

@implementation ZBThemeManager

@synthesize interfaceStyle;
@synthesize accentColor;

+ (id)sharedInstance {
    static ZBThemeManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBThemeManager new];
        instance.accentColor = [ZBSettings accentColor];
        instance.interfaceStyle = [ZBSettings interfaceStyle];
    });
    return instance;
}

+ (UIColor *)getAccentColor:(ZBAccentColor)accentColor {
    switch (accentColor) {
        case ZBAccentColorCornflowerBlue:
            return [UIColor blueCornflowerColor];
        case ZBAccentColorSystemBlue:
            return nil;
        case ZBAccentColorOrange:
            return [UIColor colorWithRed:1.0 green:0.584 blue:0.0 alpha:1.0];
        case ZBAccentColorAdaptive: {
            if ([ZBSettings interfaceStyle] >= ZBInterfaceStyleDark) {
                return [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
            }
            return [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
        }
        default:
            return [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
    }
}

+ (NSString *)localizedNameForAccentColor:(ZBAccentColor)accentColor {
    switch (accentColor) {
        case ZBAccentColorCornflowerBlue:
            return NSLocalizedString(@"Cornflower Blue", @"");
        case ZBAccentColorSystemBlue:
            return NSLocalizedString(@"None", @"");;
        case ZBAccentColorOrange:
            return NSLocalizedString(@"Orange", @"");
        case ZBAccentColorAdaptive: {
            return NSLocalizedString(@"Monochromatic", @"");
        }
        default:
            return @"I have no idea";
    }
}

+ (NSArray *)colors {
    return @[@(ZBAccentColorCornflowerBlue),
             @(ZBAccentColorOrange),
             @(ZBAccentColorAdaptive),
             @(ZBAccentColorSystemBlue)
    ];
}

+ (BOOL)useCustomTheming {
    if (@available(iOS 13.0, *)) {
        return NO;
    }
    else {
        return YES;
    }
}

- (void)updateInterfaceStyle {
    self->interfaceStyle = [ZBSettings interfaceStyle];
    self->accentColor = [ZBSettings accentColor];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configureTabBar];
        [self configureNavigationBar];
        [self configurePopupBar];
        if ([ZBThemeManager useCustomTheming]) {
            [self configureTableView];
            [self refreshViews];
        }
        else if (@available(iOS 13.0, *)) {
            if (![ZBSettings usesSystemAppearance]) {
                switch ([self interfaceStyle]) {
                    case ZBInterfaceStyleLight:
                        [[UIApplication sharedApplication] windows][0].overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
                        break;
                    case ZBInterfaceStyleDark:
                    case ZBInterfaceStylePureBlack:
                        [[UIApplication sharedApplication] windows][0].overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
                        break;
                }
            }
            else {
                [[UIApplication sharedApplication] windows][0].overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
            }
        }
    });
}

- (BOOL)darkMode {
    return interfaceStyle >= ZBInterfaceStyleDark;
}

- (void)configureTabBar {
    if (interfaceStyle == ZBInterfaceStylePureBlack) {
        if (@available(iOS 13.0, *)) {
            UITabBarAppearance *app = [[UITabBarAppearance alloc] init];
            [app configureWithOpaqueBackground];
            [app setBackgroundColor:[UIColor tableViewBackgroundColor]];
            
            [[UITabBar appearance] setStandardAppearance:app];
        }
        [[UITabBar appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
        [[UITabBar appearance] setTranslucent:NO];
    }
    else {
        [[UITabBar appearance] setBackgroundColor:nil];
        [[UITabBar appearance] setTranslucent:YES];
    }
    
    if ([ZBThemeManager useCustomTheming]) {
        [[UITabBar appearance] setTintColor:[UIColor accentColor]];
        [[UITabBar appearance] setBarStyle:[self darkMode] ? UIBarStyleBlack : UIBarStyleDefault];
    }
}

- (void)configureNavigationBar {
    if (interfaceStyle == ZBInterfaceStylePureBlack) {
        if (@available(iOS 13.0, *)) {
            UINavigationBarAppearance *app = [[UINavigationBarAppearance alloc] init];
            [app configureWithOpaqueBackground];
            [app setBackgroundColor:[UIColor tableViewBackgroundColor]];
            
            [[UINavigationBar appearance] setStandardAppearance:app];
            [[UINavigationBar appearance] setScrollEdgeAppearance:app];
        }
        [[UINavigationBar appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
        [[UINavigationBar appearance] setTranslucent:NO];
    }
    else {
        if (@available(iOS 13.0, *)) {
            UINavigationBarAppearance *app = [[UINavigationBarAppearance alloc] init];
            [app configureWithDefaultBackground];
            
            [[UINavigationBar appearance] setScrollEdgeAppearance:app];
        }
        [[UINavigationBar appearance] setBackgroundColor:nil];
        [[UINavigationBar appearance] setTranslucent:YES];
    }
    
    if ([ZBThemeManager useCustomTheming]) {
        [[UINavigationBar appearance] setTintColor:[UIColor accentColor]];
        [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor primaryTextColor]}];
        
        [[UINavigationBar appearance] setBarStyle:[self darkMode] ? UIBarStyleBlack : UIBarStyleDefault];
        
        if (@available(iOS 11.0, *)) {
            [[UINavigationBar appearance] setLargeTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor primaryTextColor]}];
        }
    }
}

- (void)configureTableView {
    if ([ZBThemeManager useCustomTheming]) {
        [[UITableView appearance] setSeparatorColor:[UIColor cellSeparatorColor]];
        [[UITableView appearance] setTintColor:[UIColor accentColor]];
        [[UITableView appearance] setBackgroundColor:[UIColor groupedTableViewBackgroundColor]];
        
        [[UITableViewCell appearance] setBackgroundColor:[UIColor cellBackgroundColor]];
//        [[UITableViewCell appearance] setTextColor:[UIColor primaryTextColor]];
        [[UITableViewCell appearance] setTintColor:[UIColor accentColor]];
        [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class], [UITableView class]]] setTextColor:[UIColor primaryTextColor]];
//        [[UILabel appearanceWhenContainedIn:[UITableViewCell class], nil] setFont:[UIFont fontWithName:@"Times" size:17.00]];
//        [[UILabel appearanceWhenContainedInInstancesOfClasses:@[NSClassFromString(@"UITableViewCellContentView")]] setTextColor:[UIColor primaryTextColor]];
    }
}

- (void)configurePopupBar {
    if (interfaceStyle == ZBInterfaceStylePureBlack) {
        [[LNPopupBar appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
        [[LNPopupBar appearance] setTranslucent:NO];
    }
    else {
        [[LNPopupBar appearance] setBackgroundColor:nil];
        [[LNPopupBar appearance] setTranslucent:YES];
    }
    if ([ZBThemeManager useCustomTheming]) {
        [[LNPopupBar appearance] setBackgroundStyle:[self darkMode] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight];
        [[LNPopupBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor primaryTextColor]}];
        [[LNPopupBar appearance] setSubtitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor secondaryTextColor]}];
    }
}

- (void)refreshViews {
    if ([ZBThemeManager useCustomTheming]) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            for (UIView *view in window.subviews) {
                [view removeFromSuperview];
                [window addSubview:view];
                CATransition *transition = [CATransition animation];
                transition.type = kCATransitionFade;
                transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                transition.fillMode = kCAFillModeForwards;
                transition.duration = 0.35;
                transition.subtype = kCATransitionFromTop;
                [view.layer addAnimation:transition forKey:nil];
            }
        }
    }
}

- (void)toggleTheme {
    if ([self darkMode]) {
        [ZBSettings setInterfaceStyle:ZBInterfaceStyleLight];
    }
    else if ([ZBSettings pureBlackMode]) {
        [ZBSettings setInterfaceStyle:ZBInterfaceStylePureBlack];
    }
    else {
        [ZBSettings setInterfaceStyle:ZBInterfaceStyleDark];
    }
    [self updateInterfaceStyle];
}

- (UIImage *)toggleImage {
    if ([self darkMode]) {
        return [UIImage imageNamed:@"Dark"];
    } else {
        return [UIImage imageNamed:@"Light"];
    }
}

@end
