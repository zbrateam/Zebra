//
//  ZBFeaturedTableViewCell.m
//  Zebra
//
//  Created by Wilson Styres on 8/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBFeaturedTableViewCell.h"
#import "ZBFeaturedCollectionViewCell.h"
#import <Extensions/UIColor+GlobalColors.h>

@implementation ZBFeaturedTableViewCell

@synthesize collectionView;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    collectionView.delegate = self;
    collectionView.dataSource = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Collection view data source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZBFeaturedCollectionViewCell *cell = (ZBFeaturedCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"featuredPackageCollectionCell" forIndexPath:indexPath];
    
    cell.tweakNameLabel.text = @"Dank Tweak";
    
    cell.tweakDescriptionLabel.text = @"Probably the best tweak out there";
    cell.tweakDescriptionLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    
    cell.repoNameLabel.text = @"CHARIZ";
    cell.repoNameLabel.textColor = [UIColor tintColor];
    
//    cell.bannerImageView.image = [UIImage imageNamed:@"banner.png"];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of items
    return 10;
}


@end
