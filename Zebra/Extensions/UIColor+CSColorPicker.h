//
// Created by CreatureSurvive on 3/17/17.
// Copyright (c) 2016 - 2019 CreatureCoding. All rights reserved.
//
#import <UIKit/UIKit.h>

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

//
// legacy api methods deprecated
//

+ (UIColor *)colorFromHexString:(NSString *)hexString 
__attribute__((deprecated("WARNING: (colorFromHexString:) has been deprecated, use cscp_colorFromHexString instead.")));

+ (NSString *)hexStringFromColor:(UIColor *)color 
__attribute__((deprecated("WARNING: (hexStringFromColor:) has been deprecated, use cscp_hexStringFromColor instead.")));

+ (NSString *)hexStringFromColor:(UIColor *)color alpha:(BOOL)include 
__attribute__((deprecated("WARNING: (hexStringFromColor:alpha:) has been deprecated, use cscp_hexStringFromColor:alpha: instead.")));

+ (CGFloat)brightnessOfColor:(UIColor *)color 
__attribute__((deprecated("WARNING: (brightnessOfColor:alpha:) has been deprecated, use cscp_brightnessOfColor instead.")));

+ (BOOL)isColorLight:(UIColor *)color 
__attribute__((deprecated("WARNING: (isColorLight:) has been deprecated, use cscp_isColorLight instead.")));

+ (BOOL)isValidHexString:(NSString *)hexString 
__attribute__((deprecated("WARNING: (isValidHexString:) has been deprecated, use cscp_isValidHexString instead.")));

- (CGFloat)alpha 
__attribute__((deprecated("WARNING: (alpha) has been deprecated, use cscp_alpha instead.")));

- (CGFloat)red 
__attribute__((deprecated("WARNING: (red) has been deprecated, use cscp_red instead.")));

- (CGFloat)green 
__attribute__((deprecated("WARNING: (green) has been deprecated, use cscp_green instead.")));

- (CGFloat)blue 
__attribute__((deprecated("WARNING: (blue) has been deprecated, use cscp_blue instead.")));

- (CGFloat)hue 
__attribute__((deprecated("WARNING: (hue) has been deprecated, use cscp_hue instead.")));

- (CGFloat)saturation 
__attribute__((deprecated("WARNING: (saturation) has been deprecated, use cscp_saturation instead.")));

- (CGFloat)brightness 
__attribute__((deprecated("WARNING: (brightness) has been deprecated, use cscp_brightness instead.")));

- (NSString *)hexString 
__attribute__((deprecated("WARNING: (hexString) has been deprecated, use cscp_hexString instead.")));

- (NSString *)hexStringWithAlpha 
__attribute__((deprecated("WARNING: (hexStringWithAlpha) has been deprecated, use cscp_hexStringWithAlpha instead.")));

- (BOOL)light 
__attribute__((deprecated("WARNING: (light) has been deprecated, use cscp_light instead.")));

- (BOOL)dark 
__attribute__((deprecated("WARNING: (dark) has been deprecated, use cscp_dark instead.")));

@end
