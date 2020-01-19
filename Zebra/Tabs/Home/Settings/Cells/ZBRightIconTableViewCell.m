//
//  ZBRightIconTableViewCell.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBRightIconTableViewCell.h"
#import "UIImageView+Zebra.h"

@implementation ZBRightIconTableViewCell

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
    CGSize size = CGSizeMake(16, 16);
    
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    [color setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.iconView.image = image;
    self.iconView.layer.cornerRadius = self.iconView.image.size.width / 2;
    self.iconView.layer.masksToBounds = YES;
}

@end
