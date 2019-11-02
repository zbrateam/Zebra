//
//  UIVisualEffectView+Theme.m
//  Zebra
//
//  Created by Wilson Styres on 10/26/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "UIVisualEffectView+Theme.h"
#import "UIColor+Zebra.h"
#import <ZBDevice.h>
#import <objc/runtime.h>

@implementation UIVisualEffectView (Theme)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class thisClass = self;
        
        SEL methodSEL = @selector(effect);
        Method og_Method = class_getInstanceMethod(thisClass, methodSEL);
        IMP methodIMP = method_getImplementation(og_Method);
        
        SEL mg_methodSEL = @selector(zb_effect);
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

- (UIVisualEffect *)zb_effect {
    if ([ZBDevice darkModeEnabled]) {
        return [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    }
    else {
        return [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    }
}

@end
