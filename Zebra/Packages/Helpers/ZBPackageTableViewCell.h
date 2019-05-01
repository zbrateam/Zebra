//
//  ZBPackageTableViewCell.h
//  Zebra
//
//  Created by Andrew Abosh on 2019-04-27.
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
@property (weak, nonatomic) IBOutlet UIImageView *isInstalledImageView;
@property (weak, nonatomic) IBOutlet UIImageView *isPaidImageView;

- (void)updateData:(ZBPackage*)package isInstalled:(BOOL)isInstalled;
@end

NS_ASSUME_NONNULL_END
