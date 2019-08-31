//
//  ZBCommunityNewsTableViewCell.m
//  Zebra
//
//  Created by Wilson Styres on 8/31/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBCommunityNewsTableViewCell.h"
#import <Extensions/UIColor+GlobalColors.h>

@implementation ZBCommunityNewsTableViewCell

@synthesize titleLabel;

- (void)awakeFromNib {
    [super awakeFromNib];

    titleLabel.textColor = [UIColor tintColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
