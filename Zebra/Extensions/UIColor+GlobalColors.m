//
//  UIColor+GlobalColors.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-04-24.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <ZBSettings.h>
#import <ZBDevice.h>
#import "UIColor+GlobalColors.h"

@implementation UIColor (GlobalColors)

+ (UIColor *)tintColor {
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:tintSelectionKey];
    if (number) {
        switch ([number integerValue]) {
            case ZBDefaultTint :
                return ([ZBDevice darkModeEnabled]) ? [UIColor colorWithRed:1.0 green:0.584 blue:0.0 alpha:1.0] : [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
            case ZBBlue :
                return [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
            case ZBOrange :
                return [UIColor colorWithRed:1.0 green:0.584 blue:0.0 alpha:1.0];
            case ZBWhiteOrBlack :
                return ([ZBDevice darkModeEnabled]) ? [UIColor colorWithRed:1 green:1 blue:1 alpha:1] : [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
            default:
                return [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
        }
    }
    if ([ZBDevice darkModeEnabled]) {
        return [UIColor colorWithRed:1.0 green:0.584 blue:0.0 alpha:1.0];
    }
    return [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
}

+ (UIColor *)navBarTintColor {
    return [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0];
}

+ (UIColor *)badgeColor {
    return [UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0];
}

// Table View Colors
+ (UIColor *)tableViewBackgroundColor {
    if ([ZBDevice darkModeEnabled]) {
        if (![ZBDevice darkModeOledEnabled] && ![ZBDevice darkModeThirteenEnabled]) {
            return [UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1.0];
        }
        return [UIColor blackColor];
    }
    return [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];
}

+ (UIColor *)cellBackgroundColor {
    if ([ZBDevice darkModeEnabled]) {
        if ([ZBDevice darkModeOledEnabled]){
            return [UIColor blackColor];
        }
        return [UIColor colorWithRed:0.11 green:0.11 blue:0.114 alpha:1.0];
    }
    return [UIColor whiteColor];
}

+ (UIColor *)selectedCellBackgroundColorLight:(BOOL)highlighted {
    return highlighted ? [UIColor colorWithRed:0.94 green:0.95 blue:1.00 alpha:1.0] : [UIColor cellBackgroundColor];
}

+ (UIColor *)selectedCellBackgroundColorDark:(BOOL)highlighted oled:(BOOL)oled {
    if (!oled) {
        return highlighted ? [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] : [UIColor colorWithRed:0.110 green:0.110 blue:0.114 alpha:1.0];
    }
    return highlighted ? [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] : [UIColor blackColor];
}

+ (UIColor *)selectedCellBackgroundColor:(BOOL)highlighted {
    if ([ZBDevice darkModeEnabled]) {
        return [self selectedCellBackgroundColorDark:highlighted oled:[ZBDevice darkModeOledEnabled]];
    }
    return [self selectedCellBackgroundColorLight:highlighted];
}

+ (UIColor *)cellPrimaryTextColor {
    if ([ZBDevice darkModeEnabled]) {
        return [UIColor whiteColor];
    }
    return [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
}

+ (UIColor *)cellSecondaryTextColor {
    if ([ZBDevice darkModeEnabled]) {
        return [UIColor lightGrayColor];
    }
    return [UIColor colorWithRed:0.43 green:0.43 blue:0.43 alpha:1.0];
}

+ (UIColor *)cellSeparatorColor {
    if ([ZBDevice darkModeEnabled]) {
        if ([ZBDevice darkModeOledEnabled]){
            return [UIColor blackColor];
        }
        return [UIColor colorWithRed:0.22 green:0.22 blue:0.23 alpha:1.0];
    }
    return [UIColor colorWithRed:0.78 green:0.78 blue:0.78 alpha:1.0];
}

+ (NSString *)hexStringFromColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    
    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}

@end
