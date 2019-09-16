//
//  ZBSourceTableViewCell.h
//  Zebra
//
//  Created by Andrew Abosh on 2019-09-09.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBSource;

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *sourceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sourceURLLabel;
@property (weak, nonatomic) IBOutlet UILabel *packageCountLabel;
- (void)updateData:(ZBSource *)source;
- (BOOL)setSpinning:(BOOL)spinning;
@end

NS_ASSUME_NONNULL_END
