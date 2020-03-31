//
//  UIColor+GlobalColors.h
//  Zebra
//
//  Created by Andrew Abosh on 2019-04-24.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ZBSettings.h>

@interface UIColor (GlobalColors)
+ (UIColor *)accentColor;
+ (UIColor *)badgeColor;
+ (UIColor *)cornflowerBlueColor;
+ (UIColor *)tableViewBackgroundColor;
+ (UIColor *)groupedTableViewBackgroundColor;
+ (UIColor *)cellBackgroundColor;
+ (UIColor *)primaryTextColor;
+ (UIColor *)secondaryTextColor;
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
