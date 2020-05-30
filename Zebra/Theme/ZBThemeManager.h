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
+ (NSString *)stringForCurrentInterfaceStyle;
+ (NSArray *)colors;
+ (UIStatusBarStyle)preferredStatusBarStyle;
+ (BOOL)useCustomTheming;
- (BOOL)darkMode;
- (void)updateInterfaceStyle;
- (void)toggleTheme;
- (void)configureNavigationBar;
- (void)configureKeyboard;
- (void)configureKeyboard:(id <UITextInputTraits>)appearance;
- (void)configureSearchBar:(UISearchBar *)searchBar;
- (void)configureTextField:(UITextField *)textField;
- (void)refreshViews;
- (UIImage *)toggleImage;
@end

NS_ASSUME_NONNULL_END
