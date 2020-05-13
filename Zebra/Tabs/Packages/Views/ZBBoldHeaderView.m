//
//  ZBBoldHeaderView.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-12.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBBoldHeaderView.h"

@implementation ZBBoldHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLabel];
    }
    return self;
}

- (void)setupLabel {
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.titleLabel setFont:[UIFont systemFontOfSize:21 weight:UIFontWeightBold]];
    
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.titleLabel];
    
    [[self.titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16] setActive:YES];
    [[self.titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:16] setActive:YES];
    [[self.titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:16] setActive:YES];
    [[self.titleLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:16] setActive:YES];
}

@end
