//
//  ZBFeaturedPackageCollectionViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2021-01-05.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBFeaturedPackageCollectionViewCell.h"
#import <Extensions/UIColor+GlobalColors.h>

@implementation ZBFeaturedPackageCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.repoLabel.textColor = [UIColor accentColor];
    self.bannerImageView.layer.cornerRadius = 6;
    self.bannerImageView.layer.masksToBounds = true;
    self.bannerImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.bannerImageView.backgroundColor = [UIColor systemPinkColor];
    self.bannerImageView.image = [UIImage imageNamed:@"featured-banner-demo"];
}

@end
