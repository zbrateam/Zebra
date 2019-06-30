//
//  UIAlertController+Theme.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 30/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "UIAlertController+Theme.h"
#import <UIColor+GlobalColors.h>

@implementation UIAlertController (Theme)

- (void)findCloseButton:(UIView *)view {
    NSArray *subviews = [view subviews];
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"_UIAlertControlleriOSActionSheetCancelBackgroundView")]) {
            UIView *bgView = [subview valueForKey:@"backgroundView"];
            bgView.backgroundColor = [UIColor cellBackgroundColor];
            return;
        }
        [self findCloseButton:subview];
    }
}

- (void)setBackgroundColor {
    // TODO: Can we make this logic faster?
    UIView *bgView = self.view.subviews[0];
    for (UIView *groupView in bgView.subviews) {
        [self findCloseButton:groupView];
        UIView *contentView = groupView.subviews[0];
        contentView.backgroundColor = [UIColor cellBackgroundColor];
    }
}

- (void)setTextColor {
    self.view.tintColor = [UIColor tintColor];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self setBackgroundColor];
    [self setTextColor];
}

@end
