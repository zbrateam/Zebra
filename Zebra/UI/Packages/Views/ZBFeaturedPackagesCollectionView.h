//
//  ZBFeaturedPackagesCollectionView.h
//  Zebra
//
//  Created by Andrew Abosh on 2021-01-06.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

@import UIKit;

@class ZBSource;

NS_ASSUME_NONNULL_BEGIN

@interface ZBFeaturedPackagesCollectionView : UICollectionView <UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic) NSArray *featuredPackages;
@property (nonatomic) CGSize itemSize;
- (void)fetch;
- (void)fetchFromSource:(ZBSource *_Nullable)source;
@end

NS_ASSUME_NONNULL_END
