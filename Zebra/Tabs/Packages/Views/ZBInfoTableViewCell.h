//
//  ZBInfoTableViewCell.h
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-12.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface ZBInfoTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chevronImageView;
- (void)setChevronHidden:(BOOL)hidden;
@end

NS_ASSUME_NONNULL_END
