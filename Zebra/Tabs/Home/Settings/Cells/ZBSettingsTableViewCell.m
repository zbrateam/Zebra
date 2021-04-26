//
//  ZBSettingsTableViewCell.m
//  Zebra
//
//  Created by absidue on 20-06-13.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewCell.h"
#import <Extensions/ZBColor.h>

@implementation ZBSettingsTableViewCell

- (void)applyStyling {
    self.textLabel.textColor = [ZBColor labelColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.textLabel.text = nil;
    self.imageView.image = nil;
}

@end
