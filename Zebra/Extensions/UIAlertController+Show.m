//
//  UIAlertController+Show.m
//  Zebra
//
//  Created by Wilson Styres on 4/10/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "UIAlertController+Show.h"
#import <objc/runtime.h>

@interface UIAlertController (Private)

@property (nonatomic, strong) UIWindow *alertWindow;

@end

@implementation UIAlertController (Private)

@dynamic alertWindow;

- (void)setAlertWindow:(UIWindow *)alertWindow {
    objc_setAssociatedObject(self, @selector(alertWindow), alertWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIWindow *)alertWindow {
    return objc_getAssociatedObject(self, @selector(alertWindow));
}

@end

@implementation UIAlertController (Show)

- (void)show {
    [self show:YES];
}

- (void)show:(BOOL)animated {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.alertWindow.rootViewController = [[UIViewController alloc] init];

        id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
        if ([delegate respondsToSelector:@selector(window)]) {
            self.alertWindow.tintColor = delegate.window.tintColor;
        }
        
        UIWindow *topWindow = [UIApplication sharedApplication].windows.lastObject;
        self.alertWindow.windowLevel = topWindow.windowLevel + 1;

        [self.alertWindow makeKeyAndVisible];
        [self.alertWindow.rootViewController presentViewController:self animated:animated completion:nil];
    });
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.alertWindow.hidden = YES;
        self.alertWindow = nil;
    });
}

@end
