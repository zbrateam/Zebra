//
//  UIColor+GlobalColors.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-04-24.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <ZBDevice.h>
#import "ZBThemeManager.h"
#import "UIColor+GlobalColors.h"

@implementation UIColor (GlobalColors)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

+ (UIColor *)accentColor {
    return [ZBThemeManager getAccentColor:[ZBSettings accentColor]];
}

+ (UIColor *)badgeColor {
    return [UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0];
}

+ (UIColor *)blueCornflowerColor {
    return [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
}

+ (UIColor *)tableViewBackgroundColor {
    if ([ZBThemeManager useCustomTheming]) {
        switch ([ZBSettings interfaceStyle]) {
            case ZBInterfaceStyleLight:
                return [UIColor whiteColor];
            case ZBInterfaceStyleDark:
            case ZBInterfaceStylePureBlack:
                return [UIColor blackColor];
        }
    }
    else {
        return [UIColor systemBackgroundColor];
    }
}

+ (UIColor *)groupedTableViewBackgroundColor {
    ZBInterfaceStyle style = [ZBSettings interfaceStyle];
    if ([ZBThemeManager useCustomTheming]) {
        switch (style) {
            case ZBInterfaceStyleLight:
                return [UIColor groupTableViewBackgroundColor];
            case ZBInterfaceStyleDark:
                return [UIColor colorWithRed:0.110 green:0.110 blue:0.118 alpha:1.0];
            case ZBInterfaceStylePureBlack:
                return [UIColor blackColor];
        }
    }
    else {
        return style == ZBInterfaceStylePureBlack ? [UIColor blackColor] : [UIColor systemGroupedBackgroundColor];
    }
}

+ (UIColor *)cellBackgroundColor {
    ZBInterfaceStyle style = [ZBSettings interfaceStyle];
    if ([ZBThemeManager useCustomTheming]) {
        switch (style) {
            case ZBInterfaceStyleLight:
                return [UIColor whiteColor];
            case ZBInterfaceStyleDark:
                return [UIColor colorWithRed:0.173 green:0.173 blue:0.180 alpha:1.0];
            case ZBInterfaceStylePureBlack:
                return [UIColor blackColor];
        }
    }
    else {
        return style == ZBInterfaceStylePureBlack ? [UIColor blackColor] : [UIColor secondarySystemGroupedBackgroundColor];
    }
}

+ (UIColor *)primaryTextColor {
    if ([ZBThemeManager useCustomTheming]) {
        switch ([ZBSettings interfaceStyle]) {
            case ZBInterfaceStyleLight:
                return [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
            case ZBInterfaceStyleDark:
            case ZBInterfaceStylePureBlack:
                return [UIColor whiteColor];
        }
    }
    else {
        return [UIColor labelColor];
    }
}

+ (UIColor *)secondaryTextColor {
    if ([ZBThemeManager useCustomTheming]) {
        switch ([ZBSettings interfaceStyle]) {
            case ZBInterfaceStyleLight:
                return [UIColor colorWithRed:0.43 green:0.43 blue:0.43 alpha:1.0];
            case ZBInterfaceStyleDark:
            case ZBInterfaceStylePureBlack:
                return [UIColor lightGrayColor];
        }
    }
    else {
        return [UIColor secondaryLabelColor];
    }
}

+ (UIColor *)cellSeparatorColor {
    if ([ZBThemeManager useCustomTheming]) {
        switch ([ZBSettings interfaceStyle]) {
            case ZBInterfaceStyleLight:
                return [UIColor colorWithRed:0.78 green:0.78 blue:0.78 alpha:1.0];
            case ZBInterfaceStyleDark:
                return [UIColor colorWithRed:0.22 green:0.22 blue:0.23 alpha:1.0];
            case ZBInterfaceStylePureBlack:
                return [UIColor blackColor];
        }
    }
    else {
        return [UIColor opaqueSeparatorColor];
    }
}

+ (UIColor *)imageBorderColor {
    switch ([ZBSettings interfaceStyle]) {
        case ZBInterfaceStyleLight:
            return [UIColor colorWithWhite:0.0 alpha:0.1];
        case ZBInterfaceStyleDark:
        case ZBInterfaceStylePureBlack:
            return [UIColor colorWithWhite:1.0 alpha:0.2];
    }
}

+ (NSString *)hexStringFromColor:(UIColor *)color {
    CGFloat r;
    CGFloat g;
    CGFloat b;
    
    [color getRed:&r green:&g blue:&b alpha:nil];
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}

#pragma clang diagnostic pop

@end
