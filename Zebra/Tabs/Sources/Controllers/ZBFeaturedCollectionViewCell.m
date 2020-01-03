//
//  ZBFeaturedCollectionViewCell.m
//  Zebra
//
//  Created by midnightchips on 5/25/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBFeaturedCollectionViewCell.h"
@import SDWebImage;

@implementation ZBFeaturedCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _imageView.layer.masksToBounds = YES;
    _imageView.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
    _titleLabel.layer.masksToBounds = NO;
    _titleLabel.layer.shouldRasterize = YES;
    _titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _titleLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    _titleLabel.layer.shadowRadius = 5.0;
    _titleLabel.layer.shadowOpacity = 1.0;
    [_titleLabel setTextColor:[UIColor whiteColor]];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:_imageView];
    [self.contentView addSubview:_titleLabel];
    self.backgroundColor = [UIColor clearColor];
    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = [UIColor clearColor].CGColor;
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 10.0f;
}

// Here we remove all the custom stuff that we added to our subclassed cell
- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
    self.imageView.frame = self.contentView.bounds;
}

@end
