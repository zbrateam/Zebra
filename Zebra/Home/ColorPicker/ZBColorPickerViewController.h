//
//  ZBColorPickerViewController.h
//  Zebra
//
//  Created by midnightchips on 6/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSGradientSelection.h"
#import "CSColorPickerBackgroundView.h"
#import "CSColorSlider.h"
#import "NSString+CSColorPicker.h"
#import "UIColor+CSColorPicker.h"

@interface ZBColorPickerViewController : UIViewController
@property NSUserDefaults *defaults;
@property NSString *key;

@property (nonatomic, strong) UIView *colorPickerContainerView;
@property (nonatomic, strong) UILabel *colorInformationLable;
@property (nonatomic, strong) UIImageView *colorTrackImageView;
@property (nonatomic, strong) CSColorPickerBackgroundView *colorPickerBackgroundView;
@property (nonatomic, strong) UIView *colorPickerPreviewView;
@property (nonatomic, strong) CSGradientSelection *gradientSelection;

@property (nonatomic, retain) CSColorSlider *colorPickerHueSlider;
@property (nonatomic, retain) CSColorSlider *colorPickerSaturationSlider;
@property (nonatomic, retain) CSColorSlider *colorPickerBrightnessSlider;
@property (nonatomic, retain) CSColorSlider *colorPickerAlphaSlider;

@property (nonatomic, retain) CSColorSlider *colorPickerRedSlider;
@property (nonatomic, retain) CSColorSlider *colorPickerGreenSlider;
@property (nonatomic, retain) CSColorSlider *colorPickerBlueSlider;

@property (nonatomic, assign) BOOL alphaEnabled;
@property (nonatomic, assign) BOOL isGradient;
@property (nonatomic, assign) NSInteger selectedIndex;

@property (nonatomic, retain) NSMutableArray<UIColor *> *colors;
@end
