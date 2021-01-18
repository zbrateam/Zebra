//
//  ZBPackageCollectionView.m
//  Zebra
//
//  Created by Wilson Styres on 1/17/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBPackageCollectionView.h"

#import <Model/ZBPackage.h>
#import <UI/Packages/Views/Cells/ZBPackageCollectionViewCell.h>

@implementation ZBPackageCollectionView

- (instancetype)init {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize;
    layout.minimumInteritemSpacing = 0;
    
    self = [super initWithFrame:CGRectZero collectionViewLayout:layout];
    
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        
        [self registerNib:[UINib nibWithNibName:@"ZBPackageCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"packageCollectionViewCell"];
        [self setBackgroundColor:[UIColor systemBackgroundColor]];
        [self setShowsHorizontalScrollIndicator:NO];
        
//        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//        self.itemSize = CGSizeMake(0, spinner.frame.size.height + 16);
    }
    
    return self;
}

#pragma mark - Properties

//- (void)setItemSize:(CGSize)itemSize {
//    @synchronized (self) {
//        if (_itemSize.height != itemSize.height) {
//            _itemSize = itemSize;
//            
//            [self setNeedsLayout];
//        }
//    }
//}

- (void)setPackages:(NSArray <ZBPackage *> *)packages {
    @synchronized (_packages) {
        _packages = packages;
        
//        [self hideSpinner];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
        });
    }
}

//#pragma mark - Activity Indicator
//
//- (void)showSpinner {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.backgroundView = self->spinner;
//        [self->spinner startAnimating];
//    });
//}
//
//- (void)hideSpinner {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.backgroundView = nil;
//        [self->spinner stopAnimating];
//    });
//}

#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _packages.count > 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return MIN(_packages.count, 10);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageCollectionViewCell *cell = [self dequeueReusableCellWithReuseIdentifier:@"packageCollectionViewCell" forIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(ZBPackageCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < _packages.count) {
        // TODO: Move code to cell
        ZBPackage *package = _packages[indexPath.row];
        cell.packageLabel.text = package.name;
        cell.descriptionLabel.text = package.packageDescription;
        [package setIconImageForImageView:cell.iconImageView];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.superview.bounds.size.width * 0.75, self.bounds.size.height / 3);
}

@end
