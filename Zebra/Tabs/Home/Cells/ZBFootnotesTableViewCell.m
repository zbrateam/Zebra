//
//  ZBFootnotesTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-09-02.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBFootnotesTableViewCell.h"

@implementation ZBFootnotesTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.deviceInfoLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
