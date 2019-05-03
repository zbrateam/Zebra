//
//  ZBPackageTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-05-01.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageTableViewCell.h"
#import <UIColor+GlobalColors.h>
#import <Packages/Helpers/ZBPackage.h>

@implementation ZBPackageTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    self.packageLabel.textColor = [UIColor cellPrimaryTextColor];
    self.descriptionLabel.textColor = [UIColor cellSecondaryTextColor];
    self.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
    self.backgroundContainerView.layer.cornerRadius = 5;
    self.backgroundContainerView.layer.masksToBounds = YES;
    self.isInstalledImageView.hidden = YES;
    self.isPaidImageView.hidden = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)updateData:(ZBPackage *)package{
    self.packageLabel.text = package.name;
    self.descriptionLabel.text = package.desc;
    
    UIImage* sectionImage = [UIImage imageNamed:package.sectionImageName];
    if (sectionImage != NULL) {
        self.iconImageView.image = sectionImage;
    }
    else {
        self.iconImageView.image = [UIImage imageNamed:@"Other"];
    }
    
    BOOL installed = [package isInstalled];
    BOOL paid = [package isPaid];
    
    self.isInstalledImageView.hidden = !installed;
    self.isPaidImageView.hidden = !paid;
    
    if (paid && !installed) {
        self.isInstalledImageView.image = [UIImage imageNamed:@"Paid"];
        self.isInstalledImageView.hidden = NO;
        self.isPaidImageView.hidden = YES;
    }
    else if (paid && installed) {
        self.isInstalledImageView.image = [UIImage imageNamed:@"Installed"];
    }
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.contentView.frame = UIEdgeInsetsInsetRect(self.contentView.frame, UIEdgeInsetsMake(0, 0, 5, 0));
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        self.backgroundContainerView.backgroundColor = [UIColor selectedCellBackgroundColor];
    }
    else {
        self.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
    }
    
}
@end
