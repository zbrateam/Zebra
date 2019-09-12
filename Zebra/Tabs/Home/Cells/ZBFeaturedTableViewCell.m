//
//  ZBFeaturedTableViewCell.m
//  Zebra
//
//  Created by Wilson Styres on 8/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBFeaturedTableViewCell.h"
#import "ZBFeaturedCollectionViewCell.h"
#import <Extensions/UIColor+Zebra.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Tabs/Home/ZBHomeTableViewController.h>

@implementation ZBFeaturedTableViewCell

@synthesize collectionView;
@synthesize packages;
@synthesize father;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    collectionView.delegate = self;
    collectionView.dataSource = self;
    packages = NULL;
}

- (void)updatePackages:(NSArray <ZBPackage *> *)newPackages {
    NSMutableArray* pickedPackages = [NSMutableArray new];
    
    NSUInteger remaining = newPackages.count >= 5 ? 5 : newPackages.count;
    
    while (remaining > 0) {
        ZBPackage *package = newPackages[arc4random_uniform((uint32_t)newPackages.count)];
            
        if (![pickedPackages containsObject:package]) {
            [pickedPackages addObject:package];
            remaining--;
        }
    }
    
    packages = (NSArray *)pickedPackages;
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Father please show %@", [packages objectAtIndex:indexPath.row]);
    [father showPackageDepiction:[packages objectAtIndex:indexPath.row]];
}

@end
