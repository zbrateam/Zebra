//
//  ZBRepoTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-05-02.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBRepoTableViewCell.h"
#import <UIColor+GlobalColors.h>

@interface ZBRepoTableViewCell () {
    UIActivityIndicatorView *spinner;
}
@end

@implementation ZBRepoTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    self.backgroundContainerView.layer.cornerRadius = 5;
    self.backgroundContainerView.layer.masksToBounds = YES;
    self.iconImageView.layer.cornerRadius = 5;
    self.iconImageView.layer.masksToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
    [spinner setColor:[UIColor grayColor]];
    spinner.frame = CGRectMake(0, 7, 0, 0);
    [self.accessoryZBView addSubview:spinner];
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
    [self showChevron:NO];
    spinner.hidden = YES;
}

- (void)setSpinning:(BOOL)spinning {
    spinner.hidden = !spinning;
    if (spinning) {
        [spinner startAnimating];
    }
    else {
        [spinner stopAnimating];
    }
}

- (void)showChevron:(BOOL)show {
    self.chevronView.hidden = !show;
}

@end
