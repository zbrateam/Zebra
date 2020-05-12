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

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self createActivityLoader];
        [self applyCustomizations];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self createActivityLoader];
    [self applyCustomizations];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.layer setCornerRadius:self.frame.size.height / 2]; // Round corners
}

- (void)applyCustomizations {
    [self setBackgroundColor:[UIColor accentColor] ?: [UIColor systemBlueColor]];
    [self setContentEdgeInsets:UIEdgeInsetsMake(6, 20, 6, 20)];
    [self.titleLabel setFont:[UIFont systemFontOfSize:13 weight:UIFontWeightBold]];
}

- (void)createActivityLoader {
    if (!activityIndicatorView) {
        activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.bounds];
        
        [activityIndicatorView setColor:[UIColor whiteColor]]; // TODO: Use theming engine
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:activityIndicatorView];
        [[activityIndicatorView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor] setActive:YES];
        [[activityIndicatorView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor] setActive:YES];
    }
}

- (void)showActivityLoader {
    [self setActivityLoaderHidden:NO];
}

- (void)hideActivityLoader {
    [self setActivityLoaderHidden:YES];
}

- (void)setActivityLoaderHidden:(BOOL)hidden {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (hidden) {
            [self->activityIndicatorView stopAnimating];
        } else {
            [self->activityIndicatorView startAnimating];
        }
        
        [self setUserInteractionEnabled:hidden];
        [self.titleLabel setAlpha:hidden ? 1 : 0];
        [self.imageView setAlpha:hidden ? 1 : 0];
    });
}

@end
