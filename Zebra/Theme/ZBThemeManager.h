//
//  ZBThemeManager.h
//  Zebra
//
//  Created by Wilson Styres on 1/15/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ZBSettings.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBThemeManager : NSObject
@property ZBInterfaceStyle interfaceStyle;
@property ZBAccentColor accentColor;
+ (id)sharedInstance;
+ (UIColor *)getAccentColor:(ZBAccentColor)accentColor;
+ (UIColor *)getAccentColor:(ZBAccentColor)accentColor forInterfaceStyle:(ZBInterfaceStyle)style;
+ (NSString *)localizedNameForAccentColor:(ZBAccentColor)accentColor;
+ (NSArray *)colors;
+ (BOOL)useCustomTheming;
- (BOOL)darkMode;
- (void)updateInterfaceStyle;
- (void)toggleTheme;
- (UIImage *)toggleImage;
@end

NS_ASSUME_NONNULL_END
