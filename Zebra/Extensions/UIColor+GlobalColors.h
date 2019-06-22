//
//  UIColor+GlobalColors.h
//  Zebra
//
//  Created by Andrew Abosh on 2019-04-24.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (GlobalColors)
+ (UIColor *)tintColor;
+ (UIColor *)navBarTintColor;
+ (UIColor *)badgeColor;
+ (UIColor *)tableViewBackgroundColor;
+ (UIColor *)cellBackgroundColor;
+ (UIColor *)cellPrimaryTextColor;
+ (UIColor *)cellSecondaryTextColor;
+ (UIColor *)selectedCellBackgroundColorLight:(BOOL)highlighted;
+ (UIColor *)selectedCellBackgroundColorDark:(BOOL)highlighted;
+ (UIColor *)selectedCellBackgroundColor:(BOOL)highlighted;
+ (UIColor *)cellSeparatorColor;
@end

@interface UIColor (Private)
+ (UIColor *)systemBlueColor;
+ (UIColor *)systemRedColor;
@end
