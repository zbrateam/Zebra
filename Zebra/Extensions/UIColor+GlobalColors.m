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

+ (UIColor *)legibleColor {
    return [ZBThemeManager getLegibleColorFor:[ZBSettings accentColor]];
}

+ (UIColor *)badgeColor {
    return [UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0];
}

+ (UIColor *)cornflowerBlueColor {
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
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (style == ZBInterfaceStylePureBlack) {
                return [UIColor blackColor];
            }
            else {
                return [UIColor systemGroupedBackgroundColor];
            }
        }];
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
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (style == ZBInterfaceStylePureBlack) {
                return [UIColor blackColor];
            }
            else {
                return [UIColor secondarySystemGroupedBackgroundColor];
            }
        }];
    }
}

+ (UIColor *)cellSelectedBackgroundColor {
    ZBInterfaceStyle style = [ZBSettings interfaceStyle];
    if ([ZBThemeManager useCustomTheming]) {
        switch (style) {
            case ZBInterfaceStyleLight:
                return [[UIColor blackColor] colorWithAlphaComponent:0.10];
            case ZBInterfaceStyleDark:
                return [[UIColor whiteColor] colorWithAlphaComponent:0.10];
            case ZBInterfaceStylePureBlack:
                return [[UIColor whiteColor] colorWithAlphaComponent:0.05];
        }
    }
    else {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (style == ZBInterfaceStylePureBlack) {
                return [[UIColor whiteColor] colorWithAlphaComponent:0.05];
            }
            else {
                return [[UIColor tertiarySystemGroupedBackgroundColor] colorWithAlphaComponent:0.75];
            }
        }];
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

+ (UIColor *)tertiaryTextColor {
    if ([ZBThemeManager useCustomTheming]) {
        switch ([ZBSettings interfaceStyle]) {
            case ZBInterfaceStyleLight:
                return [UIColor colorWithRed:0.23529411764705882 green:0.23529411764705882 blue:0.2627450980392157 alpha:0.3];
            case ZBInterfaceStyleDark:
            case ZBInterfaceStylePureBlack:
                return [UIColor colorWithRed:0.23529411764705882 green:0.23529411764705882 blue:0.2627450980392157 alpha:0.3];
        }
    }
    else {
        return [UIColor tertiaryLabelColor];
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

- (UIColor *)blendWithColor:(UIColor *)color2 progress:(CGFloat)progress {
    // Partially from https://stackoverflow.com/a/34077839
    
    progress = MIN(1.0, MAX(0.0, progress));
    
    CGFloat r1, g1, b1, r2, g2, b2;
    [self   getRed:&r1 green:&g1 blue:&b1 alpha:nil];
    [color2 getRed:&r2 green:&g2 blue:&b2 alpha:nil];
    
    CGFloat newRed   = (1.0 - progress) * r1 + progress * r2;
    CGFloat newGreen = (1.0 - progress) * g1 + progress * g2;
    CGFloat newBlue  = (1.0 - progress) * b1 + progress * b2;
    
    return [UIColor colorWithRed:newRed green:newGreen blue:newBlue alpha:1.0];
}

#pragma clang diagnostic pop

@end
