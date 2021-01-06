//
//  ZBFeaturedPackageCollectionViewCell.h
//  Zebra
//
//  Created by Andrew Abosh on 2021-01-05.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBFeaturedPackageCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *repoLabel;
@property (weak, nonatomic) IBOutlet UILabel *packageLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *bannerImageView;
@end

NS_ASSUME_NONNULL_END
