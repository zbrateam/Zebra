//
//  ZBBoldTableViewHeaderView.h
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-12.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface ZBBoldTableViewHeaderView : UITableViewHeaderFooterView
@property (strong, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@end

NS_ASSUME_NONNULL_END
