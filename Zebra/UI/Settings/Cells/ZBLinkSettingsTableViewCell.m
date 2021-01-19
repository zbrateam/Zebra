//
//  ZBLinkSettingsTableViewCell.m
//  Zebra
//
//  Created by absidue on 20-06-16.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBLinkSettingsTableViewCell.h"

@implementation ZBLinkSettingsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}

@end
