//
//  ZBLiveSearchResultTableViewCell.h
//  Zebra
//
//  Created by Andrew Abosh on 2020-03-29.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import UIKit;

@class ZBBasePackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBLiveSearchResultTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *packageIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *packageNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *isPaidImageView;
@property (weak, nonatomic) IBOutlet UIImageView *isInstalledImageView;
- (void)updateData:(ZBBasePackage *)package;
- (void)setColors;
@end

NS_ASSUME_NONNULL_END
