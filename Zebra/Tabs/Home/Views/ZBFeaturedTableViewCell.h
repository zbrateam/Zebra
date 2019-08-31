//
//  ZBFeaturedTableViewCell.h
//  Zebra
//
//  Created by Wilson Styres on 8/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBFeaturedTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource>
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@end

NS_ASSUME_NONNULL_END
