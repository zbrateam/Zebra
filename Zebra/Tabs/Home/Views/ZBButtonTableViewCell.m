//
//  ZBButtonTableViewCell.m
//  Zebra
//
//  Created by Wilson Styres on 8/31/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBButtonTableViewCell.h"
#import <Extensions/UIColor+GlobalColors.h>

@implementation ZBButtonTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.actionLabel.textColor = [UIColor tintColor];
    self.buttonView.layer.cornerRadius = 10;
    self.buttonView.layer.masksToBounds = true;
    
    self.separatorInset = UIEdgeInsetsMake(0, 0, 0, [[UIScreen mainScreen] bounds].size.width);
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (highlighted) {
            self.buttonView.backgroundColor = [UIColor tintColor];
            self.actionLabel.textColor = UIColor.whiteColor;
        }
        else {
            self.buttonView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.96 alpha:1.0];
            self.actionLabel.textColor = [UIColor tintColor];
        }
    } completion:^(BOOL finished) {
    }];
}

@end
