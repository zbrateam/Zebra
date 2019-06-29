//
//  ZBRepoTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-05-02.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBRepoTableViewCell.h"
#import <UIColor+GlobalColors.h>

@implementation ZBRepoTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    self.backgroundContainerView.layer.cornerRadius = 5;
    self.backgroundContainerView.layer.masksToBounds = YES;
    self.iconImageView.layer.cornerRadius = 5;
    self.iconImageView.layer.masksToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.contentView.frame = UIEdgeInsetsInsetRect(self.contentView.frame, UIEdgeInsetsMake(0, 0, 5, 0));
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    self.backgroundContainerView.backgroundColor = [UIColor selectedCellBackgroundColor:highlighted];
}

- (void)clearAccessoryView {
    for (UIView *subview in [self.accessoryZBView subviews]) {
        if (![subview isKindOfClass: [UIImageView class]]) {
            [subview removeFromSuperview];
        }
        else {
            subview.hidden = NO; // chevron
        }
    }
}

- (void)hideChevron {
    [self.accessoryZBView subviews][0].hidden = YES;
}

@end
