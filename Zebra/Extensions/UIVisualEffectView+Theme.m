//
//  UIVisualEffectView+Theme.m
//  Zebra
//
//  Created by Wilson Styres on 10/26/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "UIVisualEffectView+Theme.h"
#import "UIColor+GlobalColors.h"
#import <ZBDevice.h>
#import <objc/runtime.h>

@implementation UIVisualEffectView (Theme)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class thisClass = self;
        
        SEL methodSEL = @selector(layoutSubviews);
        Method og_Method = class_getInstanceMethod(thisClass, methodSEL);
        IMP methodIMP = method_getImplementation(og_Method);
        
        SEL mg_methodSEL = @selector(zb_layoutSubviews);
        Method mg_Method = class_getInstanceMethod(thisClass, mg_methodSEL);
        IMP mg_methodIMP = method_getImplementation(mg_Method);
        
        BOOL wasMethodAdded = class_addMethod(thisClass, methodSEL, mg_methodIMP, method_getTypeEncoding(mg_Method));
        
        if (wasMethodAdded) {
            class_replaceMethod(thisClass, mg_methodSEL, methodIMP, method_getTypeEncoding(og_Method));
        } else {
            method_exchangeImplementations(og_Method, mg_Method);
        }
    });
}

- (void)setAlreadyAppliedTheme:(BOOL)applied {
    NSNumber *value = [NSNumber numberWithBool:applied];
    objc_setAssociatedObject(self, @selector(alreadyAppliedTheme), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)alreadyAppliedTheme {
    NSNumber *value = objc_getAssociatedObject(self, @selector(alreadyAppliedTheme));
    return value.boolValue;
}

- (void)zb_layoutSubviews {
    if (self.alreadyAppliedTheme) {
        self.alreadyAppliedTheme = NO;
        return;
    }
    if (!self.layer.animationKeys.count) {
        self.alreadyAppliedTheme = YES;
        if ([ZBDevice darkModeEnabled]) {
            [self setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        }
        else {
            [self setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        }
    }
}

@end
