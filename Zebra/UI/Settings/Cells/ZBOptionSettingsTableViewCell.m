//
//  ZBOptionSettingsTableViewCell.m
//  Zebra
//
//  Created by absidue on 20-06-20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBOptionSettingsTableViewCell.h"
#import <Extensions/UIColor+GlobalColors.h>

@implementation ZBOptionSettingsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setChosen:NO];
    }
    return self;
}

- (void)setChosen:(BOOL)chosen {
    self.accessoryType = chosen ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (BOOL)isChosen {
    return self.accessoryType == UITableViewCellAccessoryCheckmark;
}

- (void)applyStyling {
    [super applyStyling];
    self.tintColor = [UIColor accentColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self setChosen:NO];
}

@end
