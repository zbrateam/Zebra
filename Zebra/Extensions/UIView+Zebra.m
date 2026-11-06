//
//  UIView+Zebra.m
//  Zebra
//
//  Created by Adam Demasi on 23/3/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import "UIView+Zebra.h"
#import "UIView+Private.h"

@implementation UIView (Zebra)

- (UIViewController *)viewController {
    UIResponder *responder = self;
    while (responder != nil && ![responder isKindOfClass:[UIViewController class]]) {
        responder = responder.nextResponder;
    }
    return (UIViewController *)responder;
}

- (CGFloat)cornerRadius {
    return self.layer.cornerRadius;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.masksToBounds = YES;

#ifdef __IPHONE_26_0
    if (@available(iOS 26, *)) {
        if ([self respondsToSelector:@selector(setCornerConfiguration:)]) {
            self.cornerConfiguration = [UICornerConfiguration configurationWithUniformRadius:[UICornerRadius fixedRadius:cornerRadius]];
            return;
        }
    }
#endif

    self.layer.cornerRadius = cornerRadius;

    if (@available(iOS 13, *)) {
        self.layer.cornerCurve = kCACornerCurveContinuous;
    } else if (@available(iOS 11, *)) {
        self._continuousCornerRadius = cornerRadius;
    }
}

- (CGFloat)concentricCornerRadius {
    return self.layer.cornerRadius;
}

- (void)setConcentricCornerRadius:(CGFloat)cornerRadius {
    self.layer.masksToBounds = YES;

#ifdef __IPHONE_26_0
    if (@available(iOS 26, *)) {
        if ([self respondsToSelector:@selector(setCornerConfiguration:)]) {
            self.cornerConfiguration = [UICornerConfiguration configurationWithUniformRadius:[UICornerRadius containerConcentricRadiusWithMinimum:cornerRadius]];
            return;
        }
    }
#endif

    self.cornerRadius = cornerRadius;
}

@end
