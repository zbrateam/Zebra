//
//  ZBColor.h
//  Zebra
//
//  Created by Andrew Abosh on 2019-04-24.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Private)
+ (UIColor *)systemBlueColor;
+ (UIColor *)systemRedColor;
+ (UIColor *)systemPinkColor;
+ (UIColor *)systemPurpleColor;
+ (UIColor *)systemTealColor;
+ (UIColor *)systemOrangeColor;
@end

@interface ZBColor: UIColor
+ (UIColor *)accentColor;
+ (NSString *)localizedNameForAccentColor:(NSUInteger)accentColor;
+ (UIColor *)getAccentColor:(NSUInteger)accentColor forInterfaceStyle:(UIUserInterfaceStyle)style;
- (ZBColor *)legibleColor;
+ (UIColor *)badgeColor;
+ (UIColor *)systemBackgroundColor;
+ (UIColor *)systemGroupedBackgroundColor;
+ (UIColor *)primaryTextColor;
+ (UIColor *)secondaryTextColor;
+ (UIColor *)tertiaryTextColor;
+ (UIColor *)imageBorderColor;
+ (NSString *)hexStringFromColor:(UIColor *)color;
- (UIColor *)blendWithColor:(UIColor *)color2 progress:(CGFloat)progress;
@end
