//
//  ZBPackageCollectionViewCell.h
//  Zebra
//
//  Created by Wilson Styres on 1/17/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong, nonatomic) IBOutlet UILabel *packageLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *isPaidImageView;
@property (weak, nonatomic) IBOutlet UIImageView *isOnWishlistImageView;
@property (weak, nonatomic) IBOutlet UIImageView *isInstalledImageView;
@end

NS_ASSUME_NONNULL_END
