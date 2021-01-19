//
//  ZBPackageCollectionViewCell.m
//  Zebra
//
//  Created by Wilson Styres on 1/17/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBPackageCollectionViewCell.h"

#import <Model/ZBPackage.h>
#import <Extensions/UIColor+GlobalColors.h>

@implementation ZBPackageCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.isInstalledImageView.hidden = YES;
    self.isOnWishlistImageView.hidden = YES;
    self.isPaidImageView.hidden = YES;
    
    self.iconImageView.layer.cornerRadius = self.iconImageView.frame.size.height * 0.2237;
    self.iconImageView.layer.borderWidth = 1;
    self.iconImageView.layer.borderColor = [[UIColor imageBorderColor] CGColor];
    self.iconImageView.layer.masksToBounds = YES;
}

- (void)setPackage:(ZBBasePackage *)package {
    self.packageLabel.text = package.name;
    self.descriptionLabel.text = package.packageDescription;
    [package setIconImageForImageView:self.iconImageView];
    
    self.isInstalledImageView.hidden = !package.isInstalled;
    self.isOnWishlistImageView.hidden = !package.isFavorited;
    self.isPaidImageView.hidden = !package.isPaid;
}

@end
