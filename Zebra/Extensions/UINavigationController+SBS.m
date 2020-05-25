//
//  UINavigationController+SBS.m
//  Zebra
//
//  Created by Wilson Styres on 5/24/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <objc/runtime.h>
#import "UINavigationController+SBS.h"

@implementation UINavigationController (StatusBarStyle)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class thisClass = self;
        
        SEL methodSEL = @selector(preferredStatusBarStyle);
        Method og_Method = class_getInstanceMethod(thisClass, methodSEL);
        IMP methodIMP = method_getImplementation(og_Method);
        
        SEL mg_methodSEL = @selector(zb_prefStatusBarStyle);
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

- (UIStatusBarStyle)zb_prefStatusBarStyle {
    return self.topViewController.preferredStatusBarStyle;
}

@end
