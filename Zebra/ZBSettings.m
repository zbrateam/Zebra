//
//  ZBSettings.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSettings.h"

@implementation ZBSettings

NSString *const AccentColorKey = @"AccentColor";
NSString *const UseSystemAppearanceKey = @"UseSystemAppearance";
NSString *const PureBlackModeKey = @"PureBlackMode";

+ (void)load {
    [super load];
    
    //Here is where we will set up any old settings that transfer over into new settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:tintSelectionKey]) {
        switch ([[defaults objectForKey:tintSelectionKey] integerValue]) {
            case 0:
            case 1:
                [self setAccentColor:ZBAccentColorBlue];
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
        [self setAccentColor:ZBAccentColorBlue];
        return ZBAccentColorBlue;
    }
    else {
        return [defaults integerForKey:AccentColorKey];
    }
}

+ (void)setAccentColor:(ZBAccentColor)accentColor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger:accentColor forKey:AccentColorKey];
    [defaults synchronize];
}

+ (ZBInterfaceStyle)interfaceStyle {
    return ZBInterfaceStyleLight;
}

+ (void)setInterfaceStyle:(ZBInterfaceStyle)style {
    
}

+ (BOOL)usesSystemAppearance {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:UseSystemAppearanceKey]) {
        [self setUsesSystemAppearance:true];
        return true;
    }
    else {
        return [defaults boolForKey:UseSystemAppearanceKey];
    }
}

+ (void)setUsesSystemAppearance:(BOOL)usesSystemAppearance {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:usesSystemAppearance forKey:UseSystemAppearanceKey];
    [defaults synchronize];
}

+ (BOOL)pureBlackMode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults objectForKey:PureBlackModeKey]) {
        [self setPureBlackMode:false];
        return false;
    }
    else {
        return [defaults boolForKey:PureBlackModeKey];
    }
}

+ (void)setPureBlackMode:(BOOL)pureBlackMode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:pureBlackMode forKey:PureBlackModeKey];
    [defaults synchronize];
}

+ (NSString *_Nullable)appIconName {
    return nil;
}

+ (void)setAppIconName:(NSString *_Nullable)appIconName {
    
}

+ (BOOL)wantsFeaturedPackages {
    return false;
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
    return false;
}

+ (void)setWantsCommunityNews:(BOOL)wantsCommunityNews {
    
}

+ (BOOL)liveSearch {
    return true;
}

@end
