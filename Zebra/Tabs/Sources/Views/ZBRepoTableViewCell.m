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
    self.backgroundColor = [UIColor cellBackgroundColor];
    self.iconImageView.layer.cornerRadius = 10;
    self.iconImageView.layer.masksToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.chevronView = (UIImageView *)(self.accessoryView);
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
    [spinner setColor:[UIColor grayColor]];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    self.backgroundColor= [UIColor selectedCellBackgroundColor:highlighted];
}

- (void)clearAccessoryView {
    self.accessoryView = self.chevronView;
}

- (void)setSpinning:(BOOL)spinning {
    if (spinning) {
        self.accessoryView = spinner;
        [spinner startAnimating];
    } else {
        [spinner stopAnimating];
        self.accessoryView = self.chevronView;
    }
}

@end
