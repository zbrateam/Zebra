//
//  UIColor+GlobalColors.h
//  Zebra
//
//  Created by Andrew Abosh on 2019-04-24.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum  {
    ZBDefaultTint = 0,
    ZBBlue,
    ZBOrange,
    ZBWhiteOrBlack
} ZBTintSelection;

typedef NS_ENUM(NSInteger)  {
    ZBDefaultMode = 0,
    ZBOled,
    ZBThirteen
} ZBModeSelection;

@interface UIColor (GlobalColors)
+ (UIColor *)tintColor;
+ (UIColor *)badgeColor;
+ (UIColor *)tableViewBackgroundColor;
+ (UIColor *)cellBackgroundColor;
+ (UIColor *)cellPrimaryTextColor;
+ (UIColor *)cellSecondaryTextColor;
+ (UIColor *)selectedCellBackgroundColorLight:(BOOL)highlighted;
+ (UIColor *)selectedCellBackgroundColorDark:(BOOL)highlighted oled:(BOOL)oled;
+ (UIColor *)selectedCellBackgroundColor:(BOOL)highlighted;
+ (UIColor *)cellSeparatorColor;
+ (UIColor *)imageBorderColor;
+ (NSString *)hexStringFromColor:(UIColor *)color;
@end

@interface UIColor (Private)
+ (UIColor *)systemBlueColor;
+ (UIColor *)systemRedColor;
+ (UIColor *)systemPinkColor;
+ (UIColor *)systemPurpleColor;
+ (UIColor *)systemTealColor;
+ (UIColor *)systemOrangeColor;
@end
