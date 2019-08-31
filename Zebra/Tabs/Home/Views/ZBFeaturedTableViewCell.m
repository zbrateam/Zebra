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
#import <Packages/Helpers/ZBPackage.h>

@implementation ZBFeaturedTableViewCell

@synthesize collectionView;
@synthesize packages;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    collectionView.delegate = self;
    collectionView.dataSource = self;
    packages = NULL;
}

- (void)updatePackages:(NSArray <ZBPackage *> *)newPackages {
    packages = newPackages;
    
    [collectionView reloadData];
}

#pragma mark - Collection view data source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZBFeaturedCollectionViewCell *cell = (ZBFeaturedCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"featuredPackageCollectionCell" forIndexPath:indexPath];
    
    [cell updatePackage:[packages objectAtIndex:indexPath.row]];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return packages.count;
}

@end
