//
//  PackageTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-04-27.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "PackageTableViewCell.h"
#import <UIColor+GlobalColors.h>
#import <Packages/Helpers/ZBPackage.h>

@implementation PackageTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    self.packageLabel.textColor = [UIColor cellPrimaryTextColor];
    self.descriptionLabel.textColor = [UIColor cellSecondaryTextColor];
    self.backgroundContainerView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.backgroundContainerView.layer.cornerRadius = 5;
    self.backgroundContainerView.layer.masksToBounds = YES;
    self.isInstalledImageView.hidden = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)updateData:(ZBPackage *)package {
    self.packageLabel.text = package.name;
    self.descriptionLabel.text = package.desc;
    
    if ([package isPaid]) {
        self.packageLabel.textColor = [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
        self.descriptionLabel.textColor = [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
    }
    
    UIImage* sectionImage = [UIImage imageNamed:package.sectionImageName];
    if (sectionImage != NULL) {
        self.iconImageView.image = sectionImage;
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
