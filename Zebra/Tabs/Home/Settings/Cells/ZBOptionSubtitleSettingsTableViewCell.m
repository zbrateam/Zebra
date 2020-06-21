//
//  ZBOptionSubtitleSettingsTableViewCell.m
//  Zebra
//
//  Created by absidue on 20-06-20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBOptionSubtitleSettingsTableViewCell.h"
#import <Extensions/UIColor+GlobalColors.h>

@implementation ZBOptionSubtitleSettingsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)applyStyling {
    [super applyStyling];
    self.detailTextLabel.textColor = [UIColor secondaryTextColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.detailTextLabel.text = nil;
}

@end
