//
//  UIColor+GlobalColors.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-04-24.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "UIColor+GlobalColors.h"

@implementation UIColor (GlobalColors)
+ (UIColor *)tintColor {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"darkMode"]) {
        return [UIColor colorWithRed:1.0 green:0.584 blue:0.0 alpha:1.0];
    } else {
        return [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
    }
}

+ (UIColor *)navBarTintColor {
    return [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0];
}

+ (UIColor *)badgeColor {
    return [UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0];
}

// Table View Colors
+ (UIColor *)tableViewBackgroundColor {
    return [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
}

+ (UIColor *)cellBackgroundColor {
    return [UIColor whiteColor];
}

+ (UIColor *)selectedCellBackgroundColor {
    return [UIColor colorWithRed:0.94 green:0.95 blue:1.00 alpha:1.0];
}

+ (UIColor *)selectedCellBackgroundColorDark {
    return [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
}

+ (UIColor *)cellPrimaryTextColor {
    return [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0];
}

+ (UIColor *)cellSecondaryTextColor {
    return [UIColor colorWithRed:0.43 green:0.43 blue:0.43 alpha:1.0];
}
@end
