//
// Created by CreatureSurvive on 7/28/17.
// Copyright (c) 2016 - 2019 CreatureCoding. All rights reserved.
//
#import <Foundation/NSString.h>

@class UIColor;

//
// api v1
//
@interface NSString (CSColorPicker)

//
// returns a UIColor from the hex string eg [UIColor cscp_colorFromHexString:@"#FF0000"];
// if the hex string is invalid, returns red
// supported formats include 'RGB', 'ARGB', 'RRGGBB', 'AARRGGBB', 'RGB:0.500000', 'RRGGBB:0.500000'
// all formats work with or without #
//
+ (UIColor *)cscp_colorFromHexString:(NSString *)hexString;

//
// returns true if the string is a valid hex (will pass with or without #)
+ (BOOL)cscp_isValidHexString:(NSString *)hexString;

//
// returns a string hex string representation of the string instance
//
- (UIColor *)cscp_hexColor;

//
// returns true if the string instance is a valid hex value
//
- (BOOL)cscp_validHex;

//
// returns an array of UIColors from a gradient hex array 
// eg: @"FF0000,00FF00,0000FF", or @"FF0000:0.500000,00FF00:0.500000,0000FF:0.500000" or @"FFFF0000,FF00FF00,FF0000FF"
//
- (NSArray<UIColor *> *)cscp_gradientStringColors;

//
// returns an array of CGColors for setting CAGradientLayer.colors property
// same usage as gradientStringColors
//
- (NSArray<id> *)cscp_gradientStringCGColors;

//
// legacy api methods deprecated
//

+ (UIColor *)colorFromHexString:(NSString *)hexString 
__attribute__((deprecated("WARNING: (colorFromHexString:) has been deprecated, use cscp_colorFromHexString instead.")));

+ (BOOL)isValidHexString:(NSString *)hexString 
__attribute__((deprecated("WARNING: (isValidHexString:) has been deprecated, use cscp_isValidHexString: instead.")));

- (UIColor *)hexColor 
__attribute__((deprecated("WARNING: (hexColor) has been deprecated, use cscp_hexColor instead.")));

- (BOOL)validHex 
__attribute__((deprecated("WARNING: (validHex) has been deprecated, use cscp_validHex instead.")));

- (NSArray<UIColor *> *)gradientStringColors 
__attribute__((deprecated("WARNING: (gradientStringColors) has been deprecated, use cscp_gradientStringColors instead.")));

- (NSArray<id> *)gradientStringCGColors 
__attribute__((deprecated("WARNING: (gradientStringCGColors) has been deprecated, use cscp_gradientStringCGColors instead.")));

@end