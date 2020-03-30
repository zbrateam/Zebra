//
//  ZBLiveSearchResultTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-03-29.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBLiveSearchResultTableViewCell.h"
#import "UIColor+GlobalColors.h"
@import SDWebImage;

@implementation ZBLiveSearchResultTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.isInstalledImageView.hidden = true;
    self.isPaidImageView.hidden = true;
    self.packageIconImageView.layer.cornerRadius = 6;
    self.packageIconImageView.clipsToBounds = YES;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.isInstalledImageView.tintColor = [UIColor accentColor];
}

- (void)updateData:(ZBProxyPackage *)package {
    self.packageNameLabel.text = package.name;
    self.isInstalledImageView.hidden = !package.isInstalled;
    
    UIImage *sectionImage = [UIImage imageNamed:package.section];
    if (sectionImage == NULL) {
        sectionImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Applications/Zebra.app/Sections/%@.png", package.section]];
        if (sectionImage == NULL) {
            sectionImage = [UIImage imageNamed:@"Other"];
        }
    }
    if (package.iconURL) {
        [[self packageIconImageView] sd_setImageWithURL:[package iconURL] placeholderImage:sectionImage];
    } else {
        self.packageIconImageView.image = sectionImage;
    }
}


- (void)prepareForReuse {
    [super prepareForReuse];
    [[self packageIconImageView] sd_cancelCurrentImageLoad];
    self.packageIconImageView.image = nil;
}

@end
