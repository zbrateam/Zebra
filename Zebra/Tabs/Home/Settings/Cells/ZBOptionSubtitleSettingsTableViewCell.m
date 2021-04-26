//
//  ZBOptionSubtitleSettingsTableViewCell.m
//  Zebra
//
//  Created by absidue on 20-06-20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBOptionSubtitleSettingsTableViewCell.h"
#import <Extensions/ZBColor.h>

@implementation ZBOptionSubtitleSettingsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)applyStyling {
    [super applyStyling];
    self.detailTextLabel.textColor = [ZBColor secondaryLabelColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.detailTextLabel.text = nil;
}

@end
