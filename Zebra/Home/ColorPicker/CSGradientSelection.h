//
// Created by CreatureSurvive on 4/7/19.
// Copyright (c) 2016 - 2019 CreatureCoding. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface CSGradientSelection : UIView
@property(nonatomic, weak, readonly) id target;
@property(nonatomic, assign, readonly) SEL addAction;
@property(nonatomic, assign, readonly) SEL selectAction;
@property(nonatomic, assign, readonly) SEL removeAction;
@property(nonatomic, retain, readonly) NSMutableArray<UIColor *> *colors;
@property(nonatomic, retain, readonly) NSMutableArray<UIButton *> *buttons;
@property(nonatomic, retain, readonly) CAGradientLayer *gradient;

- (instancetype)initWithSize:(CGSize)size target:(id)target addAction:(SEL)add removeAction:(SEL)remove selectAction:(SEL)select;

- (void)addColor:(UIColor *)color;
- (void)addColors:(NSArray *)colors;
- (void)removeColorAtIndex:(NSInteger)index;
- (void)setColor:(UIColor *)color atIndex:(NSInteger)index;

@end
