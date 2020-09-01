//
//  UIAlertController+Show.m
//  Zebra
//
//  Created by Wilson Styres on 4/10/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "UIAlertController+Zebra.h"
#import <objc/runtime.h>
#import <Theme/ZBThemeManager.h>

@interface ZBAlertViewController : UIViewController

@end

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

@implementation UIAlertController (Zebra)

+ (id)alertControllerWithError:(NSError *)error {
    NSString *title = error.localizedFailureReason ? error.localizedDescription : [NSString stringWithFormat:NSLocalizedString(@"Error %ld", @""), (long)error.code];
    NSString *message = error.localizedFailureReason ?: error.localizedDescription;
    return [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
}

- (void)show {
    [self show:YES];
}

- (void)show:(BOOL)animated {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.alertWindow.rootViewController = [[ZBAlertViewController alloc] init];

        id <UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
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

// Small class just to set status bar color on the alert popup
@implementation ZBAlertViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [ZBThemeManager preferredStatusBarStyle];
}

@end
