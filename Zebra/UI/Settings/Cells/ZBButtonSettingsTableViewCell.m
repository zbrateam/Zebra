//
//  ZBButtonSettingsTableViewCell.m
//  Zebra
//
//  Created by absidue on 20-06-15.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBButtonSettingsTableViewCell.h"
#import <Extensions/UIColor+GlobalColors.h>

@implementation ZBButtonSettingsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)applyStyling {
    [super applyStyling];
    self.textLabel.textColor = [UIColor accentColor] ?: [UIColor systemBlueColor];
}
@end
