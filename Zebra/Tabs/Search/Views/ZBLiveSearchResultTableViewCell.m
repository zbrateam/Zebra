//
//  ZBLiveSearchResultTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-03-29.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBLiveSearchResultTableViewCell.h"
#import <Extensions/UIColor+GlobalColors.h>
@import SDWebImage;

@implementation ZBLiveSearchResultTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.isInstalledImageView.hidden = YES;
    self.isPaidImageView.hidden = YES;
    self.packageIconImageView.layer.cornerRadius = 6;
    self.packageIconImageView.clipsToBounds = YES;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.isInstalledImageView.tintColor = [UIColor accentColor];
}

- (void)updateData:(ZBProxyPackage *)package {
    self.packageNameLabel.text = package.name;
    self.isInstalledImageView.hidden = !package.isInstalled;
    
    [package setIconImageForImageView:self.packageIconImageView];
}

- (void)setColors {
    self.packageNameLabel.textColor = [UIColor primaryTextColor];
    self.backgroundColor = [UIColor cellBackgroundColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [[self packageIconImageView] sd_cancelCurrentImageLoad];
    self.packageIconImageView.image = nil;
}

@end
