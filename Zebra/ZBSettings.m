//
//  ZBSettings.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSettings.h"

@implementation ZBSettings

+ (void)load {
    [super load];
    
    //Here is where we will set up any old settings that transfer over into new settings
    
}

+ (ZBAccentColor)accentColor {
    return ZBAccentColorBlue;
}

+ (void)setAccentColor:(ZBAccentColor)accentColor {
    
}

+ (ZBInterfaceStyle)style {
    return ZBInterfaceStyleLight;
}

+ (void)setStyle:(ZBInterfaceStyle)style {
    
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
