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
@property (strong, nonatomic) IBOutlet UIView *backgroundContainerView;
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong, nonatomic) IBOutlet UILabel *packageLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIImageView *isPaidImageView;
@property (strong, nonatomic) IBOutlet UIImageView *isInstalledImageView;
@property (strong, nonatomic) IBOutlet UILabel *queueStatusLabel;
@property (strong, nonatomic) IBOutlet UILabel *authorAndSourceAndSize;
- (void)updateData:(ZBPackage *)package;
- (void)updateData:(ZBPackage *)package calculateSize:(BOOL)calculateSize showVersion:(BOOL)showVersion;
- (void)updateQueueStatus:(ZBPackage *)package;
- (void)setColors;
@end

NS_ASSUME_NONNULL_END
