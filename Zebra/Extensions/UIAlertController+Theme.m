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

- (void)recursiveSetColor:(UIView *)view {
    NSArray *subviews = [view subviews];
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"_UIAlertControlleriOSActionSheetCancelBackgroundView")]) {
            UIView *bgView = [subview valueForKey:@"backgroundView"];
            bgView.backgroundColor = [UIColor cellBackgroundColor];
            return;
        }
        else if ([subview isKindOfClass:[UILabel class]]) {
            ((UILabel *)subview).textColor = [UIColor tintColor];
        }
        else {
            subview.backgroundColor = [UIColor cellBackgroundColor];
        }
        [self recursiveSetColor:subview];
    }
}

- (void)setBackgroundColor {
    for (UIView *groupView in self.view.subviews) {
        [self recursiveSetColor:groupView];
    }
}

- (void)setTextColor {
    self.view.tintColor = [UIColor tintColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setBackgroundColor];
    [self setTextColor];
}

@end
