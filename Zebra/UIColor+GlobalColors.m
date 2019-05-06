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
    return [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];;
}

+ (UIColor *)cellBackgroundColor {
    return [UIColor whiteColor];
}

+ (UIColor *)selectedCellBackgroundColor {
    return [UIColor colorWithRed:0.94 green:0.95 blue:1.00 alpha:1.0];
}

+ (UIColor *)cellPrimaryTextColor {
    return [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0];
}

+ (UIColor *)cellSecondaryTextColor {
    return [UIColor colorWithRed:0.43 green:0.43 blue:0.43 alpha:1.0];
}
@end
