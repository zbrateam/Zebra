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
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
