//
//  UIRefreshControl+Theme.m
//  Zebra
//
//  Created by Wilson Styres on 12/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "UIRefreshControl+Theme.h"

#import <ZBDevice.h>
#import <objc/runtime.h>

@implementation UIRefreshControl (Theme)

+ (void)load {
    if ([ZBDevice themingAllowed]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Class class = [self class];

            SEL originalSelector = @selector(didMoveToWindow);
            SEL swizzledSelector = @selector(zb_didMoveToWindow);

            Method originalMethod = class_getInstanceMethod(class, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

            BOOL didAddMethod =
                class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));

            if (didAddMethod) {
                class_replaceMethod(class,
                    swizzledSelector,
                    method_getImplementation(originalMethod),
                    method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        });
    }
}


- (void)zb_didMoveToWindow {
    [self zb_didMoveToWindow];
    for (UIView *view in [self allSubviewsForView:self]) {
        if ([view.layer isKindOfClass:NSClassFromString(@"CAReplicatorLayer")] && view.subviews.count > 0) {
            view.subviews[0].backgroundColor = [UIColor whiteColor];
            view.subviews[0].tintColor = [UIColor whiteColor];
        }
    }
}

- (NSArray <UIView *> *)allSubviewsForView:(UIView *)view {
    NSMutableArray *arr = [NSMutableArray new];
    for (UIView *subview in [view subviews]) {
        [arr addObject:subview];
        [arr addObjectsFromArray:[self allSubviewsForView:subview]];
    }
    return arr;
}

@end
