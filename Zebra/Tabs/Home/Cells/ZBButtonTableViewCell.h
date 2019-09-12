//
//  ZBButtonTableViewCell.h
//  Zebra
//
//  Created by Wilson Styres on 8/31/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBButtonTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *actionLabel;
@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (strong, nonatomic) NSString *actionLink;
@end

NS_ASSUME_NONNULL_END
