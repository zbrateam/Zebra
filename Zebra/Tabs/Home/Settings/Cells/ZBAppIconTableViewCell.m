//
//  ZBAppIconTableViewCell.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBAppIconTableViewCell.h"
#import "UIImageView+Zebra.h"

@implementation ZBAppIconTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.label.font = self.textLabel.font;
}

- (void)setAppIcon:(UIImage *)icon border:(BOOL)border {
    self.iconView.image = icon;
    
    [self.iconView resize:CGSizeMake(30, 30) applyRadius:true];
    
    if (border) {
        [self.iconView applyBorder];
    }
    else {
        [self.iconView removeBorder];
    }
}

- (void)setColor:(UIColor *)color {
    self.iconView.image = icon;
    
    [self.iconView resize:CGSizeMake(30, 30) applyRadius:true];
    
    if (border) {
        [self.iconView applyBorder];
    }
    else {
        [self.iconView removeBorder];
    }
}

@end
