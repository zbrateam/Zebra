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
    self.defaults = [NSUserDefaults standardUserDefaults];
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
    if (highlighted) {
        if ([self.defaults boolForKey:@"darkMode"]) {
            self.backgroundContainerView.backgroundColor = [UIColor selectedCellBackgroundColorDark];
        } else {
            self.backgroundContainerView.backgroundColor = [UIColor selectedCellBackgroundColor];
        }
    }
    else {
        if ([self.defaults boolForKey:@"darkMode"]) {
            self.backgroundContainerView.backgroundColor = [UIColor colorWithRed:0.110 green:0.110 blue:0.114 alpha:1.0];
        } else {
            self.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
        }
        
    }
    
}

- (void)clearAccessoryView {
    UIView *chevron;
    for (UIView *subview in [self.accessoryZBView subviews]) {
        if (![subview isKindOfClass: [UIImageView class]]) {
            [subview removeFromSuperview];
        }
        else {
            chevron = subview;
        }
    }
    chevron.hidden = NO;
}

- (void)hideChevron {
    [self.accessoryZBView subviews][0].hidden = YES;
}


@end
