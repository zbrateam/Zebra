//
//  ZBChangelogTableViewCell.m
//  Zebra
//
//  Created by Wilson Styres on 8/27/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBChangelogTableViewCell.h"

@implementation ZBChangelogTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.dateLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
