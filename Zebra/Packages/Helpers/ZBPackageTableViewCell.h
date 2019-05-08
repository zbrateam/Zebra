//
//  ZBPackageTableViewCell.h
//  Zebra
//
//  Created by Andrew Abosh on 2019-05-01.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBPackage;
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *backgroundContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *packageLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *isPaidImageView;
@property (weak, nonatomic) IBOutlet UIImageView *isInstalledImageView;

- (void)updateData:(ZBPackage*)package;

@end

NS_ASSUME_NONNULL_END
