//
//  ZBColor.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-04-24.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBColor.h"

#import <ZBSettings.h>

@implementation ZBColor

+ (UIColor *)accentColor {
    if ([ZBSettings usesSystemAccentColor]) return nil; //nil here defaults to the view tint color (switches have different tints)
    
    ZBAccentColor accentColor = [ZBSettings accentColor];
    return [self getAccentColor:accentColor];
}

+ (UIColor *)getAccentColor:(NSUInteger)accentColor forInterfaceStyle:(UIUserInterfaceStyle)style {
    UITraitCollection *traits = [UITraitCollection traitCollectionWithUserInterfaceStyle:style];
    return [[self getAccentColor:accentColor] resolvedColorWithTraitCollection:traits];
}

+ (UIColor *)getAccentColor:(NSUInteger)accentColor {
    switch (accentColor) {
        case ZBAccentColorMonochrome:
            return [UIColor colorNamed:@"Monochrome"];
        case ZBAccentColorShark:
            return [UIColor colorNamed:@"Shark"];
        case ZBAccentColorGoldenTainoi:
            return [UIColor colorNamed:@"Golden Tainoi"];
        case ZBAccentColorPastelRed:
            return [UIColor colorNamed:@"Pastel Red"];
        case ZBAccentColorLotusPink:
            return [UIColor colorNamed:@"Lotus Pink"];
        case ZBAccentColorIrisBlue:
            return [UIColor colorNamed:@"Iris Blue"];
        case ZBAccentColorMountainMeadow:
            return [UIColor colorNamed:@"Mountain Meadow"];
        case ZBAccentColorAquaVelvet:
            return [UIColor colorNamed:@"Aqua Velvet"];
        case ZBAccentColorRoyalBlue:
            return [UIColor colorNamed:@"Royal Blue"];
        case ZBAccentColorPurpleHeart:
            return [UIColor colorNamed:@"Purple Heart"];
        case ZBAccentColorStorm:
            return [UIColor colorNamed:@"Storm"];
        case ZBAccentColorEmeraldCity:
            return [UIColor colorNamed:@"Emerald City"];
        case ZBAccentColorCornflowerBlue:
        default:
            return [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
    }
}

+ (NSString *)localizedNameForAccentColor:(NSUInteger)accentColor {
    if ([ZBSettings usesSystemAccentColor]) return NSLocalizedString(@"System", @"");
    switch (accentColor) {
        case ZBAccentColorAquaVelvet:
            return NSLocalizedString(@"Aqua Velvet", @"");
        case ZBAccentColorCornflowerBlue:
            return NSLocalizedString(@"Cornflower Blue", @"");
        case ZBAccentColorGoldenTainoi:
            return NSLocalizedString(@"Golden Tainoi", @"");
        case ZBAccentColorIrisBlue:
            return NSLocalizedString(@"Iris Blue", @"");
        case ZBAccentColorLotusPink:
            return NSLocalizedString(@"Lotus Pink", @"");
        case ZBAccentColorMonochrome:
            return NSLocalizedString(@"Monochrome", @"");
        case ZBAccentColorMountainMeadow:
            return NSLocalizedString(@"Mountain Meadow", @"");
        case ZBAccentColorPastelRed:
            return NSLocalizedString(@"Pastel Red", @"");
        case ZBAccentColorPurpleHeart:
            return NSLocalizedString(@"Purple Heart", @"");
        case ZBAccentColorRoyalBlue:
            return NSLocalizedString(@"Royal Blue", @"");
        case ZBAccentColorShark:
            return NSLocalizedString(@"Shark", @"");
        case ZBAccentColorStorm:
            return NSLocalizedString(@"Storm", @"");
        default:
            return @"I have no idea";
    }
}

+ (UIColor *)badgeColor {
    return [UIColor colorNamed:@"Badge Color"];
}

+ (UIColor *)systemBackgroundColor {
    if (@available(iOS 13.0, macCatalyst 13.0, *)) {
        return [super systemBackgroundColor];
    } else {
        return [super whiteColor];
    }
}

+ (UIColor *)systemGroupedBackgroundColor {
    if (@available(iOS 13.0, macCatalyst 13.0, *)) {
        return [super systemGroupedBackgroundColor];
    } else {
        return [super groupTableViewBackgroundColor];
    }
}

+ (UIColor *)labelColor {
    if (@available(iOS 13.0, macCatalyst 13.0, *)) {
        return [super labelColor];
    } else {
        return [super colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    }
}

+ (UIColor *)secondaryLabelColor {
    if (@available(iOS 13.0, macCatalyst 13.0, *)) {
        return [super secondaryLabelColor];
    } else {
        return [super colorWithRed:0.43 green:0.43 blue:0.43 alpha:1.0];
    }
}

+ (UIColor *)tertiaryLabelColor {
    if (@available(iOS 13.0, macCatalyst 13.0, *)) {
        return [super secondaryLabelColor];
    } else {
        return [super colorWithRed:0.23529411764705882 green:0.23529411764705882 blue:0.2627450980392157 alpha:0.3];
    }
}

+ (UIColor *)imageBorderColor {
    return [UIColor colorNamed:@"Image Border Color"];
}

+ (NSString *)hexStringFromColor:(UIColor *)color {
    CGFloat r;
    CGFloat g;
    CGFloat b;
    
    [color getRed:&r green:&g blue:&b alpha:nil];
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}

// https://github.com/mattjgalloway/MJGFoundation/blob/master/Source/Categories/UIColor/UIColor-MJGAdditions.m
- (ZBColor *)legibleColor {
    ZBColor *black = (ZBColor *)[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    ZBColor *white = (ZBColor *)[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        
    float blackDiff = [self luminosityDifference:black];
    float whiteDiff = [self luminosityDifference:white];
        
    return (blackDiff > whiteDiff) ? black : white;
}

// https://github.com/mattjgalloway/MJGFoundation/blob/master/Source/Categories/UIColor/UIColor-MJGAdditions.m
- (CGFloat)luminosity {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;

    BOOL success = [self getRed:&red green:&green blue:&blue alpha:&alpha];

    if (success)
        return 0.2126 * pow(red, 2.2f) + 0.7152 * pow(green, 2.2f) + 0.0722 * pow(blue, 2.2f);

    CGFloat white;

    success = [self getWhite:&white alpha:&alpha];
    if (success)
        return pow(white, 2.2f);

    return -1;
}

// https://github.com/mattjgalloway/MJGFoundation/blob/master/Source/Categories/UIColor/UIColor-MJGAdditions.m
- (CGFloat)luminosityDifference:(ZBColor *)otherColor {
    CGFloat l1 = [self luminosity];
    CGFloat l2 = [otherColor luminosity];

    if (l1 >= 0 && l2 >= 0) {
        if (l1 > l2) {
            return (l1+0.05f) / (l2+0.05f);
        } else {
            return (l2+0.05f) / (l1+0.05f);
        }
    }
    
    return 0.0f;
}

- (UIColor *)blendWithColor:(UIColor *)color2 progress:(CGFloat)progress {
    // Partially from https://stackoverflow.com/a/34077839
    
    progress = MIN(1.0, MAX(0.0, progress));
    
    CGFloat r1, g1, b1, r2, g2, b2;
    [self   getRed:&r1 green:&g1 blue:&b1 alpha:nil];
    [color2 getRed:&r2 green:&g2 blue:&b2 alpha:nil];
    
    CGFloat newRed   = (1.0 - progress) * r1 + progress * r2;
    CGFloat newGreen = (1.0 - progress) * g1 + progress * g2;
    CGFloat newBlue  = (1.0 - progress) * b1 + progress * b2;
    
    return [UIColor colorWithRed:newRed green:newGreen blue:newBlue alpha:1.0];
}

@end
