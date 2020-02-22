//
//  UIAlertController+Theme.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 30/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "UIAlertController+Theme.h"
#import <UIColor+GlobalColors.h>
#import <objc/runtime.h>
#import <ZBDevice.h>
#import <Theme/ZBThemeManager.h>

@implementation UIAlertController (Theme)

+ (void)load {
    if ([ZBThemeManager useCustomTheming]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Class thisClass = self;
            
            SEL methodSEL = @selector(viewDidLayoutSubviews);
            Method og_Method = class_getInstanceMethod(thisClass, methodSEL);
            IMP methodIMP = method_getImplementation(og_Method);
            
            SEL mg_methodSEL = @selector(zb_viewDidLayoutSubviews);
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
}

- (void)recursiveSetColor:(UIView *)view {
    NSArray *subviews = [view subviews];
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"_UIAlertControlleriOSActionSheetCancelBackgroundView")]) {
            UIView *bgView = [subview valueForKey:@"backgroundView"];
            bgView.backgroundColor = [UIColor cellBackgroundColor];
            return;
        } else if ([subview isKindOfClass:[UILabel class]]) {
            ((UILabel *)subview).textColor = [UIColor primaryTextColor];
        }
        [self recursiveSetColor:subview];
    }
}

- (void)setBackgroundColor {
    UIView *view = self.view;
    @try {
        view.subviews[0].subviews[0].subviews[0].backgroundColor = [UIColor cellBackgroundColor];
    }
    @catch (NSException *e) {
        return;
    }
    
    for (UIView *groupView in view.subviews) {
        [self recursiveSetColor:groupView];
    }
    do {
        if ([view isKindOfClass:NSClassFromString(@"_UIPopoverView")]) {
            UIView *backgroundView = [view valueForKey:@"_backgroundView"];
            UIView *visualEffectView = [backgroundView valueForKey:@"_blurView"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
                visualEffectView.subviews[1].backgroundColor = [UIColor cellBackgroundColor];
            });
            return;
        }
    } while ((view = view.superview));
}

- (void)setTextColor {
    dispatch_async(dispatch_get_main_queue(), ^{
        //Set title color
        if (self.title) {
            NSString *title = self.title;
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
            [attributedTitle addAttributes:@{NSForegroundColorAttributeName: [UIColor primaryTextColor]} range:NSMakeRange(0, title.length)];
            
            [self setValue:attributedTitle forKey:@"attributedTitle"];
        }
        
        //Set message color
        if (self.message) {
            NSString *message = self.message;
            NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:message];
            [attributedMessage addAttributes:@{NSForegroundColorAttributeName: [UIColor primaryTextColor]} range:NSMakeRange(0, message.length)];
            
            [self setValue:attributedMessage forKey:@"attributedMessage"];
        }
    });
}

- (void)zb_viewDidLayoutSubviews {
    self.view.tintColor = [UIColor accentColor];
    if (self.preferredStyle == UIAlertControllerStyleActionSheet) {
        [self setTextColor];
    }
    [self zb_viewDidLayoutSubviews];
    [self setBackgroundColor];
}

@end
