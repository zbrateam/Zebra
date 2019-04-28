//
//  PackageTableViewCell.h
//  Zebra
//
//  Created by Andrew Abosh on 2019-04-27.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PackageTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *backgroundContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *packageLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *isInstalledImageView;
@end

NS_ASSUME_NONNULL_END
