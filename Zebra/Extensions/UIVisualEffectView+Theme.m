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

BOOL alreadySet;

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

- (void)zb_layoutSubviews {
    if (alreadySet) {
        alreadySet = false;
        return;
    }
    if ([ZBDevice darkModeEnabled]) {
        alreadySet = true;
        self.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    }
    else {
        alreadySet = true;
        self.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    }
}

@end
