//
//  ZBLinkTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-14.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBLinkTableViewCell.h"
#import <Extensions/ZBColor.h>

@implementation ZBLinkTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self applyCustomizations];
}

- (void)applyCustomizations {
    [self.nameLabel setTextColor:[ZBColor accentColor] ?: [UIColor systemBlueColor]];
    [self.iconImageView setTintColor:[ZBColor accentColor] ?: [UIColor systemBlueColor]];
    [self.contentView setBackgroundColor:[ZBColor systemBackgroundColor]];
}

@end
