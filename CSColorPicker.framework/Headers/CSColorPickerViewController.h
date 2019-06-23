//
// Created by CreatureSurvive on 3/17/17.
// Copyright (c) 2016 - 2019 CreatureCoding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSColorObject.h"
#import "CSColorPickerDelegate.h"
#import "UIColor+CSColorPicker.h"
#import "NSString+CSColorPicker.h"

@interface CSColorPickerViewController : UIViewController

@property (nonatomic, assign) BOOL alphaEnabled;
@property (nonatomic, retain) UIColor *color;
@property (nonatomic, retain) NSMutableArray<UIColor *> *colors;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, assign) UIBlurEffectStyle blurStyle;
@property (nonatomic, assign) id<CSColorPickerDelegate> delegate;

- (instancetype)initWithColor:(UIColor *)color showingAlpha:(BOOL)alphaEnabled;
- (instancetype)initWithColors:(NSArray<UIColor*> *)colors showingAlpha:(BOOL)alphaEnabled;
- (instancetype)initWithColorObject:(CSColorObject *)color showingAlpha:(BOOL)alphaEnabled;

@end
