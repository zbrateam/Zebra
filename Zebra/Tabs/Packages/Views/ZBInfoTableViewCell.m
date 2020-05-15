//
//  ZBInfoTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-12.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBInfoTableViewCell.h"

@implementation ZBInfoTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // TODO: Tint chevron
}

- (void)setChevronHidden:(BOOL)hidden {
    self.chevronImageView.hidden = hidden;
}

@end
