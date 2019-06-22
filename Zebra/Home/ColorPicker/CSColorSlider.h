//
// Created by CreatureSurvive on 3/17/17.
// Copyright (c) 2016 - 2019 CreatureCoding. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    CSColorSliderTypeHue = 0,
    CSColorSliderTypeSaturation = 1,
    CSColorSliderTypeBrightness = 2,
    CSColorSliderTypeRed = 3,
    CSColorSliderTypeGreen = 4,
    CSColorSliderTypeBlue = 5,
    CSColorSliderTypeAlpha = 6
};
typedef NSUInteger CSColorSliderType;

@interface CSColorSlider : UISlider

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColor *maxColor;
@property (nonatomic, strong) UIColor *selectedColor;

@property (nonatomic, strong) UILabel *sliderLabel;
@property (nonatomic, assign) CSColorSliderType sliderType;

@property (nonatomic, assign) NSUInteger colorTrackHeight;

- (instancetype)initWithFrame:(CGRect)frame sliderType:(CSColorSliderType)sliderType label:(NSString *)label startColor:(UIColor *)startColor;
- (void)updateTrackImage;
@end
