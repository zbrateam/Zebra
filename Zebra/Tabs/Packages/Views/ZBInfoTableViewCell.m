//
//  ZBInfoTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-12.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBInfoTableViewCell.h"
#import "Zebra-Swift.h"

@implementation ZBInfoTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self applyCustomizations];
}

- (void)applyCustomizations {
    [self.contentView setBackgroundColor:[UIColor systemBackgroundColor]];
}

- (void)setChevronHidden:(BOOL)hidden {
    self.chevronImageView.hidden = hidden;
}

@end
