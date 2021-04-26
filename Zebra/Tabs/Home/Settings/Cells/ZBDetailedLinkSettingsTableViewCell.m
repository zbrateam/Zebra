//
//  ZBDetailedLinkSettingsTableViewCell.m
//  Zebra
//
//  Created by absidue on 20-06-16.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBDetailedLinkSettingsTableViewCell.h"
#import <Extensions/ZBColor.h>

@implementation ZBDetailedLinkSettingsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)applyStyling {
    [super applyStyling];
    self.detailTextLabel.textColor = [ZBColor secondaryTextColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.detailTextLabel.text = nil;
}

@end
