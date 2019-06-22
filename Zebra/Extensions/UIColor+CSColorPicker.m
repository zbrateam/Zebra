//
// Created by CreatureSurvive on 3/17/17.
// Copyright (c) 2016 - 2019 CreatureCoding. All rights reserved.
//

#import "UIColor+CSColorPicker.h"

@interface UIColor (Private)
+ (CGFloat)_colorComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length 
__attribute__((deprecated("WARNING: (_colorComponentFrom:start:length:) has been deprecated, use _cscp_colorComponentFrom:start:length: instead.")));
+ (CGFloat)_cscp_colorComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length;
@end

@implementation UIColor (CSColorPicker)

+ (UIColor *)cscp_colorFromHexString:(NSString *)hexString {

    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
    CGFloat alpha, red, blue, green;

    if ([colorString rangeOfString:@":"].location != NSNotFound) {
        NSArray *stringComponents = [colorString componentsSeparatedByString:@":"];
        colorString = stringComponents[0];
        alpha = [stringComponents[1] floatValue] ? : 1.0f;
    }

    if (![UIColor cscp_isValidHexString:colorString]) {
        return [UIColor redColor];
    }

    switch ([colorString length]) {
        case 3:
            alpha = 1.0f;
            red = [self _cscp_colorComponentFrom:colorString start:0 length:1];
            green = [self _cscp_colorComponentFrom:colorString start:1 length:1];
            blue = [self _cscp_colorComponentFrom:colorString start:2 length:1];
            break;
        case 4:
            alpha = [self _cscp_colorComponentFrom:colorString start:0 length:1];
            red = [self _cscp_colorComponentFrom:colorString start:1 length:1];
            green = [self _cscp_colorComponentFrom:colorString start:2 length:1];
            blue = [self _cscp_colorComponentFrom:colorString start:3 length:1];
            break;
        case 6:
            alpha = 1.0f;
            red = [self _cscp_colorComponentFrom:colorString start:0 length:2];
            green = [self _cscp_colorComponentFrom:colorString start:2 length:2];
            blue = [self _cscp_colorComponentFrom:colorString start:4 length:2];
            break;
        case 8:
            alpha = [self _cscp_colorComponentFrom:colorString start:0 length:2];
            red = [self _cscp_colorComponentFrom:colorString start:2 length:2];
            green = [self _cscp_colorComponentFrom:colorString start:4 length:2];
            blue = [self _cscp_colorComponentFrom:colorString start:6 length:2];
            break;
        default:
            alpha = 100.0f;
            red = green = blue = 255.0f;
            break;
    }
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (CGFloat)_cscp_colorComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length {
    NSString *substring = [string substringWithRange:NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat:@"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString:fullHex] scanHexInt:&hexComponent];
    return hexComponent / 255.0;
}

+ (BOOL)cscp_isValidHexString:(NSString *)hexString {
    NSCharacterSet *hexChars = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"] invertedSet];
    return (NSNotFound == [[[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString] rangeOfCharacterFromSet:hexChars].location);
}

+ (NSString *)cscp_hexStringFromColor:(UIColor *)color {

    CGFloat red, green, blue;
    [color getRed:&red green:&green blue:&blue alpha:nil];
    red = roundf(red * 255.0f);
    green = roundf(green * 255.0f);
    blue = roundf(blue * 255.0f);

    return [[NSString stringWithFormat:@"%02x%02x%02x", (int)red, (int)green, (int)blue] uppercaseString];
}

+ (NSString *)cscp_hexStringFromColor:(UIColor *)color alpha:(BOOL)include {

    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    red = roundf(red * 255.0f);
    green = roundf(green * 255.0f);
    blue = roundf(blue * 255.0f);
    alpha = roundf(alpha * 255.0f);

    return include ? [[NSString stringWithFormat:@"%02x%02x%02x%02x", (int)alpha, (int)red, (int)green, (int)blue] uppercaseString] :
                     [[NSString stringWithFormat:@"%02x%02x%02x", (int)red, (int)green, (int)blue] uppercaseString];
}

+ (CGFloat)cscp_brightnessOfColor:(UIColor *)color {
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return (((red * 255) * 299) + ((green * 255) * 587) + ((blue * 255) * 114)) / 1000;
}

+ (BOOL)cscp_isColorLight:(UIColor *)color {
    return ([UIColor cscp_brightnessOfColor:color] >= 128.0);
}

- (CGFloat)cscp_alpha {
    CGFloat a;
    [self getWhite:NULL alpha:&a];
    return a;
}

- (CGFloat)cscp_red {
    CGFloat r;
    [self getRed:&r green:NULL blue:NULL alpha:NULL];
    return r;
}

- (CGFloat)cscp_green {
    CGFloat g;
    [self getRed:NULL green:&g blue:NULL alpha:NULL];
    return g;
}

- (CGFloat)cscp_blue {
    CGFloat b;
    [self getRed:NULL green:NULL blue:&b alpha:NULL];
    return b;
}

- (CGFloat)cscp_hue {
    CGFloat h;
    [self getHue:&h saturation:NULL brightness:NULL alpha:NULL];
    return h;
}

- (CGFloat)cscp_saturation {
    CGFloat s;
    [self getHue:NULL saturation:&s brightness:NULL alpha:NULL];
    return s;
}

- (CGFloat)cscp_brightness {
    CGFloat b;
    [self getHue:NULL saturation:NULL brightness:&b alpha:NULL];
    return b;
}

- (NSString *)cscp_hexString {
    return [UIColor cscp_hexStringFromColor:self];
}

- (NSString *)cscp_hexStringWithAlpha {
    return [UIColor cscp_hexStringFromColor:self alpha:YES];
}

- (BOOL)cscp_light {
    return [UIColor cscp_isColorLight:self];
}

- (BOOL)cscp_dark {
    return ![UIColor cscp_isColorLight:self];
}

//
// legacy api methods deprecated
//

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    return [self cscp_colorFromHexString:hexString];
}

+ (CGFloat)colorComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length {
    return [self _cscp_colorComponentFrom:string start:start length:length];
}

+ (BOOL)isValidHexString:(NSString *)hexString {
    return [self cscp_isValidHexString:hexString];
}

+ (NSString *)hexStringFromColor:(UIColor *)color {
    return [self cscp_hexStringFromColor:color];
}

+ (NSString *)hexStringFromColor:(UIColor *)color alpha:(BOOL)include {
    return [self cscp_hexStringFromColor:color alpha:include];
}

+ (CGFloat)brightnessOfColor:(UIColor *)color {
    return [self cscp_brightnessOfColor:color];
}

+ (BOOL)isColorLight:(UIColor *)color {
    return [self cscp_isColorLight:color];
}

- (CGFloat)alpha {
    return [self cscp_alpha];
}

- (CGFloat)red {
    return [self cscp_red];
}

- (CGFloat)green {
    return [self cscp_green];
}

- (CGFloat)blue {
    return [self cscp_blue];
}

- (CGFloat)hue {
    return [self cscp_hue];
}

- (CGFloat)saturation {
    return [self cscp_saturation];
}

- (CGFloat)brightness {
    return [self cscp_brightness];
}

- (NSString *)hexString {
    return [self cscp_hexString];
}

- (NSString *)hexStringWithAlpha {
    return [self cscp_hexStringWithAlpha];
}

- (BOOL)light {
    return [self cscp_light];
}

- (BOOL)dark {
    return [self cscp_dark];
}

@end