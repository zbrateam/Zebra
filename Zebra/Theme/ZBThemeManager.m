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
    return [self getAccentColor:accentColor forInterfaceStyle:[ZBSettings interfaceStyle]];
}

+ (UIColor *)getAccentColor:(ZBAccentColor)accentColor forInterfaceStyle:(ZBInterfaceStyle)style {
    if ([ZBSettings usesSystemAccentColor]) return nil; //nil here defaults to the view tint color (switches have different tints)
    
    BOOL darkMode = style >= ZBInterfaceStyleDark;
    switch (accentColor) {
        case ZBAccentColorCornflowerBlue:
            return darkMode ? [UIColor colorWithRed:0.52 green:0.60 blue:1.00 alpha:1.0] : [UIColor cornflowerBlueColor];
        case ZBAccentColorMonochrome:
            return darkMode ? [UIColor whiteColor] : [UIColor blackColor];
        case ZBAccentColorShark:
            return darkMode ? [UIColor colorWithRed:0.78 green:0.84 blue:0.90 alpha:1.0] : [UIColor colorWithRed:0.13 green:0.18 blue:0.24 alpha:1.0];
        case ZBAccentColorGoldenTainoi:
            return darkMode ? [UIColor colorWithRed:1.00 green:0.79 blue:0.34 alpha:1.0] : [UIColor colorWithRed:1.00 green:0.62 blue:0.26 alpha:1.0];
        case ZBAccentColorPastelRed:
            return darkMode ? [UIColor colorWithRed:0.93 green:0.32 blue:0.33 alpha:1.0] : [UIColor colorWithRed:1.00 green:0.42 blue:0.42 alpha:1.0];
        case ZBAccentColorLotusPink:
            return darkMode ? [UIColor colorWithRed:0.95 green:0.41 blue:0.88 alpha:1.0] : [UIColor colorWithRed:1.00 green:0.62 blue:0.95 alpha:1.0];
        case ZBAccentColorIrisBlue:
            return darkMode ? [UIColor colorWithRed:0.28 green:0.86 blue:0.98 alpha:1.0] : [UIColor colorWithRed:0.04 green:0.74 blue:0.89 alpha:1.0];
        case ZBAccentColorMountainMeadow:
            return darkMode ? [UIColor colorWithRed:0.06 green:0.67 blue:0.52 alpha:1.0] : [UIColor colorWithRed:0.11 green:0.82 blue:0.63 alpha:1.0];
        case ZBAccentColorAquaVelvet:
            return darkMode ? [UIColor colorWithRed:0.00 green:0.64 blue:0.64 alpha:1.0] : [UIColor colorWithRed:0.00 green:0.82 blue:0.83 alpha:1.0];
        case ZBAccentColorRoyalBlue:
            return darkMode ? [UIColor colorWithRed:0.18 green:0.53 blue:0.87 alpha:1.0] : [UIColor colorWithRed:0.33 green:0.63 blue:1.00 alpha:1.0];
        case ZBAccentColorPurpleHeart:
            return darkMode ? [UIColor colorWithRed:0.33 green:0.32 blue:0.93 alpha:1.0] : [UIColor colorWithRed:0.42 green:0.36 blue:0.91 alpha:1.0];
        case ZBAccentColorStorm:
            return darkMode ? [UIColor colorWithRed:0.51 green:0.58 blue:0.65 alpha:1.0] : [UIColor colorWithRed:0.34 green:0.40 blue:0.45 alpha:1.0];
        default:
            return [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
    }
}

+ (NSString *)localizedNameForAccentColor:(ZBAccentColor)accentColor {
    if ([ZBSettings usesSystemAccentColor]) return NSLocalizedString(@"System", @"");
    switch (accentColor) {
        case ZBAccentColorAquaVelvet:
            return NSLocalizedString(@"Aqua Velvet", @"");
        case ZBAccentColorCornflowerBlue:
            return NSLocalizedString(@"Cornflower Blue", @"");
        case ZBAccentColorGoldenTainoi:
            return NSLocalizedString(@"Golden Tainoi", @"");
        case ZBAccentColorIrisBlue:
            return NSLocalizedString(@"Iris Blue", @"");
        case ZBAccentColorLotusPink:
            return NSLocalizedString(@"Lotus Pink", @"");
        case ZBAccentColorMonochrome:
            return NSLocalizedString(@"Monochrome", @"");
        case ZBAccentColorMountainMeadow:
            return NSLocalizedString(@"Mountain Meadow", @"");
        case ZBAccentColorPastelRed:
            return NSLocalizedString(@"Pastel Red", @"");
        case ZBAccentColorPurpleHeart:
            return NSLocalizedString(@"Purple Heart", @"");
        case ZBAccentColorRoyalBlue:
            return NSLocalizedString(@"Royal Blue", @"");
        case ZBAccentColorShark:
            return NSLocalizedString(@"Shark", @"");
        case ZBAccentColorStorm:
            return NSLocalizedString(@"Storm", @"");
        default:
            return @"I have no idea";
    }
}

+ (NSArray *)colors {
    NSMutableArray *colors = [NSMutableArray new];
    for (ZBAccentColor color = ZBAccentColorAquaVelvet; color <= ZBAccentColorStorm; color++) {
        [colors addObject:@(color)];
    }
    return colors;
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
    self.interfaceStyle = [ZBSettings interfaceStyle];
    self.accentColor = [ZBSettings accentColor];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configureTabBar];
        [self configureNavigationBar];
        [self configurePopupBar];
        [self configureTableView];
        [self configureKeyboard];
        if ([ZBThemeManager useCustomTheming]) {
            [self refreshViews];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"darkMode" object:self];
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
    return self.interfaceStyle >= ZBInterfaceStyleDark;
}

- (void)configureTabBar {
    if (self.interfaceStyle == ZBInterfaceStylePureBlack) {
        if (@available(iOS 13.0, *)) {
            UITabBarAppearance *app = [[UITabBarAppearance alloc] init];
            [app configureWithOpaqueBackground];
            [app setBackgroundColor:[UIColor blackColor]];
            
            [[UITabBar appearance] setStandardAppearance:app];
        }
        [[UITabBar appearance] setBackgroundColor:[UIColor blackColor]];
        [[UITabBar appearance] setTranslucent:NO];
    }
    else {
        [[UITabBar appearance] setBackgroundColor:nil];
        [[UITabBar appearance] setTranslucent:YES];
    }
    
    [[UITabBar appearance] setTintColor:[UIColor accentColor]];
    if ([ZBThemeManager useCustomTheming]) {
        [[UITabBar appearance] setBarStyle:[self darkMode] ? UIBarStyleBlack : UIBarStyleDefault];
    }
}

- (void)configureNavigationBar {
    [[UINavigationBar appearance] setBackgroundColor:nil];
    [[UINavigationBar appearance] setTranslucent:YES];
    
    [[UINavigationBar appearance] setTintColor:[UIColor accentColor]];
    if ([ZBThemeManager useCustomTheming]) {
        [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor primaryTextColor]}];
        [[UINavigationBar appearance] setBarStyle:[self darkMode] ? UIBarStyleBlack : UIBarStyleDefault];
        
        if (@available(iOS 11.0, *)) {
            [[UINavigationBar appearance] setLargeTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor primaryTextColor]}];
        }
    }
}

- (void)configureTableView {
    [[UITableView appearance] setTintColor:[UIColor accentColor]];
    [[UITableView appearance] setBackgroundColor:[UIColor groupedTableViewBackgroundColor]];
    [[UITableViewCell appearance] setBackgroundColor:[UIColor cellBackgroundColor]];
    [[UITableViewCell appearance] setTintColor:[UIColor accentColor]];
    if ([ZBThemeManager useCustomTheming]) {
        [[UITableView appearance] setSeparatorColor:[UIColor cellSeparatorColor]];
        [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class], [UITableView class]]] setTextColor:[UIColor primaryTextColor]];
    }
}

- (void)configurePopupBar {
    if (self.interfaceStyle == ZBInterfaceStylePureBlack) {
        [[LNPopupBar appearance] setBackgroundColor:[UIColor blackColor]];
        [[LNPopupBar appearance] setTranslucent:NO];
    }
    else {
        [[LNPopupBar appearance] setBackgroundColor:nil];
        [[LNPopupBar appearance] setTranslucent:YES];
    }
    if ([ZBThemeManager useCustomTheming]) {
        if (self.interfaceStyle >= ZBInterfaceStyleDark) {
            [[LNPopupBar appearance] setBackgroundStyle:UIBlurEffectStyleDark];
        }
        else {
            [[LNPopupBar appearance] setBackgroundStyle:UIBlurEffectStyleLight];
        }
    }
}

- (void)configureKeyboard {
    if ([ZBThemeManager useCustomTheming]) {
        if ([self darkMode]) {
            [[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDark];
        }
        else {
            [[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDefault];
        }
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
