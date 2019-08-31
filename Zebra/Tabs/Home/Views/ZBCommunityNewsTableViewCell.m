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
@synthesize tagLabel;

- (void)awakeFromNib {
    [super awakeFromNib];

    titleLabel.textColor = [UIColor tintColor];
    tagLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
