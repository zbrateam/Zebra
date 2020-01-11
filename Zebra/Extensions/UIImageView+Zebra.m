//
//  UIImageView+Zebra.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "UIColor+GlobalColors.h"
#import "UIImageView+Zebra.h"

@implementation UIImageView (Zebra)

- (void)applyBorder {
    self.layer.borderColor = [UIColor imageBorderColor].CGColor;
    self.layer.borderWidth = 0.5;
    self.clipsToBounds = YES;
}

- (void)removeBorder {
    self.layer.borderColor = [UIColor clearColor].CGColor;
    self.layer.borderWidth = 0.0;
    self.clipsToBounds = YES;
}

- (void)resize:(CGSize)size applyRadius:(BOOL)radius {
    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
    
    CGRect rect = CGRectMake(0.0, 0.0, size.width, size.height);
    [self.image drawInRect:rect];
    
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (radius) {
        self.layer.cornerRadius = 0.2237 * size.width;
        self.clipsToBounds = YES;
    }
}

@end
