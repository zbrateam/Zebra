//
//  ZBSettingsTableViewCell.m
//  Zebra
//
//  Created by absidue on 20-06-13.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewCell.h"
#import <Extensions/UIColor+GlobalColors.h>

@implementation ZBSettingsTableViewCell

- (void)applyStyling {
    self.backgroundColor = [UIColor cellBackgroundColor];
    self.textLabel.textColor = [UIColor primaryTextColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.textLabel.text = nil;
    self.imageView.image = nil;
}

@end
