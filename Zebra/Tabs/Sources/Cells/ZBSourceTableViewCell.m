//
//  ZBSourceTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-09-09.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSourceTableViewCell.h"

@implementation ZBSourceTableViewCell {
    UIActivityIndicatorView *spinner;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.iconImageView.layer.cornerRadius = 6;
    self.iconImageView.layer.masksToBounds = true;
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
    [spinner setColor:[UIColor grayColor]];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
//    self.backgroundColor= [UIColor selectedCellBackgroundColor:highlighted];
}

- (void)clearAccessoryView {
    self.accessoryView = nil;
}

- (void)setSpinning:(BOOL)spinning {
    if (spinning) {
        self.accessoryView = spinner;
        [spinner startAnimating];
    } else {
        [spinner stopAnimating];
        self.accessoryView = nil;
    }
}
@end
