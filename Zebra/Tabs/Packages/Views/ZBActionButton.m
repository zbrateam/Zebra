//
//  ZBActionButton.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-11.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBActionButton.h"
#import "UIColor+GlobalColors.h"

@interface ZBActionButton () {
    UIActivityIndicatorView *activityIndicatorView;
}
@end

@implementation ZBActionButton

- (void)awakeFromNib {
    [super awakeFromNib];
    [self applyCustomizations];
}

- (void)applyCustomizations {
    [self setBackgroundColor:[UIColor accentColor]];
    [self setContentEdgeInsets:UIEdgeInsetsMake(6, 20, 6, 20)];
    [self.layer setCornerRadius:self.frame.size.height / 2];
    [self.titleLabel setFont:[UIFont systemFontOfSize:13 weight:UIFontWeightBold]];
}

- (void)showActivityLoader {
    if (activityIndicatorView == nil) {
        activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.bounds];
        [activityIndicatorView setColor:[UIColor whiteColor]]; // TODO: Use theming engine
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:activityIndicatorView];
        [[activityIndicatorView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor] setActive:YES];
        [[activityIndicatorView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor] setActive:YES];
    }
    [self setActivityLoaderHidden:NO];
}

- (void)hideActivityLoader {
    [self setActivityLoaderHidden:YES];
}

- (void)setActivityLoaderHidden:(BOOL)hidden {
    if (hidden) {
        [activityIndicatorView stopAnimating];
    } else {
        [activityIndicatorView startAnimating];
    }
    [self setUserInteractionEnabled:hidden];
    [self.titleLabel setAlpha:hidden ? 1 : 0];
}

@end
