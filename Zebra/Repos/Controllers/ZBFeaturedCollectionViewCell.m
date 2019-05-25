//
//  ZBFeaturedCollectionViewCell.m
//  Zebra
//
//  Created by midnightchips on 5/25/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBFeaturedCollectionViewCell.h"

@implementation ZBFeaturedCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageView.layer.masksToBounds = TRUE;
}

- (UIImageView *) imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        [self.contentView addSubview:_imageView];
    }
    return _imageView;
}

// Here we remove all the custom stuff that we added to our subclassed cell
-(void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
    self.imageView.frame = self.contentView.bounds;
    
}



@end
