//
//  UINavigationBar+Progress.m
//  Zebra
//
//  Created by Wilson Styres on 1/6/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "UINavigationBar+Progress.h"

#import <objc/runtime.h>

@implementation UINavigationBar (Progress)

- (UIProgressView *)navProgressView {
    UIProgressView *progress = objc_getAssociatedObject(self, "navProgressView");
    if (!progress) {
        progress = [UIProgressView.alloc initWithProgressViewStyle:UIProgressViewStyleBar];
        [self addSubview:progress];
        
        [progress.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
        [progress.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [progress.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        progress.translatesAutoresizingMaskIntoConstraints = NO;
        
        objc_setAssociatedObject(self, "navProgressView", progress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return progress;
}

@end
