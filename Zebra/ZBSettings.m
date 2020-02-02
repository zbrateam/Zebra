//
//  ZBSettings.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSettings.h"

#import <UIKit/UIApplication.h>
#import <UIKit/UIScreen.h>
#import <UIKit/UIWindow.h>

@implementation ZBSettings

NSString *const AccentColorKey = @"AccentColor";
NSString *const UseSystemAppearanceKey = @"UseSystemAppearance";
NSString *const InterfaceStyleKey = @"InterfaceStyle";
NSString *const PureBlackModeKey = @"PureBlackMode";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

+ (void)load {
    [super load];
    
    //Here is where we will set up any old settings that transfer over into new settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:tintSelectionKey]) {
        switch ([[defaults objectForKey:tintSelectionKey] integerValue]) {
            case 0:
            case 1:
                [self setAccentColor:ZBAccentColorCornflowerBlue];
            case 2:
                [self setAccentColor:ZBAccentColorOrange];
            case 3:
                [self setAccentColor:ZBAccentColorAdaptive];
                
        }
        [defaults removeObjectForKey:tintSelectionKey];
    }
    
    if ([defaults boolForKey:thirteenModeKey]) {
        [self setInterfaceStyle:ZBInterfaceStyleDark];
    }
    
    if ([defaults boolForKey:oledModeKey]) {
        [self setInterfaceStyle:ZBInterfaceStylePureBlack];
    }
    
    if ([defaults boolForKey:darkModeKey]) {
        [self setInterfaceStyle:ZBInterfaceStyleDark];
    }
    
    //Set other defaults
    if (![defaults objectForKey:liveSearchKey]) {
        [defaults setBool:YES forKey:liveSearchKey];
    }
    if (![defaults objectForKey:wantsFeaturedKey]) {
        [defaults setBool:YES forKey:wantsFeaturedKey];
    }
    if (![defaults objectForKey:wantsNewsKey]) {
        [defaults setBool:YES forKey:wantsNewsKey];
    }
    if (![defaults objectForKey:wishListKey]) {
        [defaults setObject:[NSArray new] forKey:wishListKey];
    }
    
    [defaults synchronize];
}

+ (ZBAccentColor)accentColor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:AccentColorKey]) {
        [self setAccentColor:ZBAccentColorCornflowerBlue];
        return ZBAccentColorCornflowerBlue;
    }
    return [defaults integerForKey:AccentColorKey];
}

+ (void)setAccentColor:(ZBAccentColor)accentColor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger:accentColor forKey:AccentColorKey];
    [defaults synchronize];
}

+ (ZBInterfaceStyle)interfaceStyle {
    if ([self usesSystemAppearance]) {
        UIUserInterfaceStyle style = [[[UIScreen mainScreen] traitCollection] userInterfaceStyle];
        switch (style) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight:
                return ZBInterfaceStyleLight;
            case UIUserInterfaceStyleDark:
                return [self pureBlackMode] ? ZBInterfaceStylePureBlack : ZBInterfaceStyleDark;
        }
    }
    else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if (![defaults objectForKey:InterfaceStyleKey]) {
            [self setInterfaceStyle:ZBInterfaceStyleLight];
            return ZBInterfaceStyleLight;
        }
        return [defaults integerForKey:InterfaceStyleKey];
    }
}

+ (void)setInterfaceStyle:(ZBInterfaceStyle)style {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger:style forKey:InterfaceStyleKey];
    [defaults synchronize];
}

+ (BOOL)usesSystemAppearance {
    if (@available(iOS 13.0, *)) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if (![defaults objectForKey:UseSystemAppearanceKey]) {
            [self setUsesSystemAppearance:YES];
            return YES;
        }
        return [defaults boolForKey:UseSystemAppearanceKey];
    }
    return NO;
}

+ (void)setUsesSystemAppearance:(BOOL)usesSystemAppearance {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:usesSystemAppearance forKey:UseSystemAppearanceKey];
    [defaults synchronize];
}

+ (BOOL)pureBlackMode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:PureBlackModeKey]) {
        [self setPureBlackMode:NO];
        return NO;
    }
    return [defaults boolForKey:PureBlackModeKey];
}

+ (void)setPureBlackMode:(BOOL)pureBlackMode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:pureBlackMode forKey:PureBlackModeKey];
    [defaults synchronize];
}

+ (NSString *_Nullable)appIconName {
    if (@available(iOS 10.3, *)) {
        return [[UIApplication sharedApplication] alternateIconName];
    }
    return NULL;
}

+ (void)setAppIconName:(NSString *_Nullable)appIconName {
    
}

+ (BOOL)wantsFeaturedPackages {
    return NO;
}

+ (void)setWantsFeaturedPackages:(BOOL)wantsFeaturedPackages {
    
}

+ (ZBFeaturedType)featuredPackagesType {
    return ZBFeaturedTypeSource;
}

+ (void)setFeaturedPackagesType:(ZBFeaturedType)featuredPackagesType {
    
}

+ (NSArray *)sourceBlacklist {
    return NULL;
}

+ (BOOL)wantsCommunityNews {
    return YES;
}

+ (void)setWantsCommunityNews:(BOOL)wantsCommunityNews {
    
}

+ (BOOL)liveSearch {
    return YES;
}

#pragma clang diagnostic pop

@end
