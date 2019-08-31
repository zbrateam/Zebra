//
//  ZBFeaturedCollectionViewCell.h
//  Zebra
//
//  Created by Wilson Styres on 8/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBFeaturedCollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UILabel *repoNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *tweakNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *tweakDescriptionLabel;
@property (strong, nonatomic) IBOutlet UIImageView *bannerImageView;

@end

NS_ASSUME_NONNULL_END
