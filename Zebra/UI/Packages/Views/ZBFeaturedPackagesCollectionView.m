//
//  ZBFeaturedPackagesCollectionView.m
//  Zebra
//
//  Created by Andrew Abosh on 2021-01-06.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBFeaturedPackagesCollectionView.h"
#import "ZBFeaturedPackageCollectionViewCell.h"

@implementation ZBFeaturedPackagesCollectionView

NSString *const ZBFeaturedCollectionViewCellReuseIdentifier = @"ZBFeaturedPackageCollectionViewCell"; // TODO: Move this to ZBFeaturedPackageCollectionViewCell?

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        [self setBackgroundColor:[UIColor systemBackgroundColor]];
        [self registerNib:[UINib nibWithNibName:@"ZBFeaturedPackageCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:ZBFeaturedCollectionViewCellReuseIdentifier];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize;
    layout.sectionInset = UIEdgeInsetsMake(16, 16, 16, 16);
    
    self = [self initWithFrame:frame collectionViewLayout:layout];
    return self;
}

#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 6;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [self dequeueReusableCellWithReuseIdentifier:ZBFeaturedCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(263, 148);
}

@end
