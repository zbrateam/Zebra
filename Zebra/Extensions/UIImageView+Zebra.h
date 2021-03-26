//
//  UIImageView+Zebra.h
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (Zebra)

- (void)applyBorder;
- (void)removeBorder;
- (void)setColor:(UIColor *)color;
- (void)setLeftColor:(UIColor *)leftColor rightColor:(UIColor *)rightColor;
- (void)resize:(CGSize)size applyRadius:(BOOL)radius;

@end

NS_ASSUME_NONNULL_END
