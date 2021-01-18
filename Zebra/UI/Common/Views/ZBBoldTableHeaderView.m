//
//  ZBBoldTableHeaderView.m
//  Zebra
//
//  Created by Wilson Styres on 1/18/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBBoldTableHeaderView.h"

@implementation ZBBoldTableHeaderView

- (ZBBoldHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[ZBBoldHeaderView alloc] init];
        
        [self addSubview:_headerView];
        [NSLayoutConstraint activateConstraints:@[
            [_headerView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_headerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_headerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_headerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        ]];
        _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return _headerView;
}

- (UILabel *)titleLabel {
    return self.headerView.titleLabel;
}

- (UIButton *)actionButton {
    return self.headerView.actionButton;
}

@end
