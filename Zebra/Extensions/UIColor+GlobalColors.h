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
+ (UIColor *)legibleColor;
+ (UIColor *)badgeColor;
+ (UIColor *)cornflowerBlueColor;
+ (UIColor *)tableViewBackgroundColor;
+ (UIColor *)groupedTableViewBackgroundColor;
+ (UIColor *)cellBackgroundColor;
+ (UIColor *)cellSelectedBackgroundColor;
+ (UIColor *)primaryTextColor;
+ (UIColor *)secondaryTextColor;
+ (UIColor *)tertiaryTextColor;
+ (UIColor *)cellSeparatorColor;
+ (UIColor *)imageBorderColor;
+ (NSString *)hexStringFromColor:(UIColor *)color;
- (UIColor*)blendWithColor:(UIColor*)color2 progress:(CGFloat)progress;
@end

@interface UIColor (Private)
+ (UIColor *)systemBlueColor;
+ (UIColor *)systemRedColor;
+ (UIColor *)systemPinkColor;
+ (UIColor *)systemPurpleColor;
+ (UIColor *)systemTealColor;
+ (UIColor *)systemOrangeColor;
@end
