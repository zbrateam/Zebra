//
//  ZBPackageCollectionView.h
//  Zebra
//
//  Created by Wilson Styres on 1/17/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZBPackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageCollectionView : UICollectionView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic) NSArray <ZBPackage *> *packages;
@property (nonatomic) CGSize itemSize;
@end

NS_ASSUME_NONNULL_END
