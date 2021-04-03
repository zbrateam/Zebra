//
//  ZBLinkTableViewCell.h
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-14.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBLinkTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@end

NS_ASSUME_NONNULL_END
