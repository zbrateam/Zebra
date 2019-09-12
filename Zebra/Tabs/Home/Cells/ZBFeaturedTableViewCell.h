//
//  ZBFeaturedTableViewCell.h
//  Zebra
//
//  Created by Wilson Styres on 8/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBPackage;
@class ZBHomeTableViewController;

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBFeaturedTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource>
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSArray<ZBPackage *> *packages;
@property (weak, nonatomic) ZBHomeTableViewController *father;

- (void)updatePackages:(NSArray <ZBPackage *> *)newPackages;
@end

NS_ASSUME_NONNULL_END
