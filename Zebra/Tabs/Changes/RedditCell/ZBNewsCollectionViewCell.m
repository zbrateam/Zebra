//
//  ZBNewsCollectionViewCell.m
//  Zebra
//
//  Created by midnightchips on 7/8/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBNewsCollectionViewCell.h"
@import SDWebImage;

@implementation ZBNewsCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _backgroundImage.layer.masksToBounds = YES;
    _backgroundImage.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
    _postTag.layer.masksToBounds = NO;
    _postTag.layer.shouldRasterize = YES;
    _postTag.layer.shadowColor = [UIColor blackColor].CGColor;
    _postTag.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    _postTag.layer.shadowRadius = 20.0;
    _postTag.layer.shadowOpacity = 1.0;
    _postTitle.layer.masksToBounds = NO;
    _postTitle.layer.shouldRasterize = YES;
    _postTitle.layer.shadowColor = [UIColor blackColor].CGColor;
    _postTitle.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    _postTitle.layer.shadowRadius = 20.0;
    _postTitle.layer.shadowOpacity = 1.0;
    [_postTag setTextColor:[UIColor whiteColor]];
    [_postTitle setTextColor:[UIColor whiteColor]];
    _backgroundImage.contentMode = UIViewContentModeScaleAspectFill;
    [_backgroundImage setClipsToBounds:TRUE];
    [self.contentView addSubview:_backgroundImage];
    [self.contentView addSubview:_postTag];
    [self.contentView addSubview:_postTitle];
    [self createBlur];
    self.backgroundColor = [UIColor clearColor];
    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = [UIColor clearColor].CGColor;
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 10.0f;
}

- (void)createBlur {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    // always fill the view
    blurEffectView.frame = self.backgroundImage.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurEffectView.alpha = .35;
    [self.backgroundImage addSubview:blurEffectView];
}

// Shadow gradient
/*
- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradient.frame = self.backgroundImage.frame;
}
 self.gradient = [CAGradientLayer layer];
 self.gradient.frame = self.backgroundImage.frame;
 self.gradient.colors = @[(id)[UIColor colorWithWhite:1 alpha:0].CGColor, (id)[UIColor colorWithRed:0 green:0 blue:0 alpha:.75].CGColor];
 [self.backgroundImage.layer insertSublayer:self.gradient atIndex:0];*/

/*UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
 UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
 // always fill the view
 blurEffectView.frame = self.backgroundImage.bounds;
 blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
 blurEffectView.alpha = .3;
 [self.backgroundImage addSubview:blurEffectView];*/

- (void)prepareForReuse {
    [super prepareForReuse];
    self.backgroundImage.image = nil;
    self.backgroundImage.frame = self.contentView.bounds;
}

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    [self setNeedsLayout];
    [self layoutIfNeeded];
    layoutAttributes.frame = CGRectMake(0, 0, 263, 148);
    return layoutAttributes;
}

@end
