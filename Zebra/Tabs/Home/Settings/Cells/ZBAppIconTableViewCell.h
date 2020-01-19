//
//  ZBAppIconTableViewCell.h
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBAppIconTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *iconView;
@property (strong, nonatomic) IBOutlet UILabel *label;
- (void)setAppIcon:(UIImage *)icon border:(BOOL)border;
- (void)setColor:(UIImage *)icon border:(BOOL)border;
@end

NS_ASSUME_NONNULL_END
