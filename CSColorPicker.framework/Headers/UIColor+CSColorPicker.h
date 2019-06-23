//
// Created by CreatureSurvive on 3/17/17.
// Copyright (c) 2016 - 2019 CreatureCoding. All rights reserved.
//

#import <UIKit/UIColor.h>

@interface UIColor (CSColorPicker)

//
// returns a UIColor from the hex string eg [UIColor colorFromHexString:@"#FF0000"];
// if the hex string is invalid, returns red
// supported formats include 'RGB', 'ARGB', 'RRGGBB', 'AARRGGBB', 'RGB:0.500000', 'RRGGBB:0.500000'
// all formats work with or without #
//
+ (UIColor *)cscp_colorFromHexString:(NSString *)hexString;

//
// returns a NSString representation of a UIColor in hex format eg [UIColor cscp_hexStringFromColor:[UIColor redColor]]; outputs @"#FF0000"
//
+ (NSString *)cscp_hexStringFromColor:(UIColor *)color;

//
// returns a NSString representation of a UIColor in hex format eg [UIColor cscp_hexStringFromColor:[UIColor redColor] alpha:YES]; outputs @"#FFFF0000"
//
+ (NSString *)cscp_hexStringFromColor:(UIColor *)color alpha:(BOOL)include;

//
// returns the brightness of the color where black = 0.0 and white = 256.0
// credit goes to https://w3.org for the algorithm
//
+ (CGFloat)cscp_brightnessOfColor:(UIColor *)color;

//
// returns true if the color is light using csp_brightnessOfColor > 0.5
//
+ (BOOL)cscp_isColorLight:(UIColor *)color;

//
// returns true if the string is a valid hex (will pass with or without #)
//
+ (BOOL)cscp_isValidHexString:(NSString *)hexString;

//
// the alpha component the color instance
//
- (CGFloat)cscp_alpha;

//
// the red component the color instance
//
- (CGFloat)cscp_red;

//
// the green component the color instance
//
- (CGFloat)cscp_green;

//
// the blue component the color instance
//
- (CGFloat)cscp_blue;

//
// the hue component the color instance
//
- (CGFloat)cscp_hue;

//
// the saturation component the color instance
//
- (CGFloat)cscp_saturation;

//
// the brightness component the color instance
//
- (CGFloat)cscp_brightness;

//
// the hexString value of the color instance
//
- (NSString *)cscp_hexString;

//
// the hexString value of the color instance with alpha included
//
- (NSString *)cscp_hexStringWithAlpha;

//
// is this color instance light
//
- (BOOL)cscp_light;

//
// is this color instance dark
//
- (BOOL)cscp_dark;

@end
