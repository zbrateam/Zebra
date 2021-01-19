//
//  ZBBoldCollectionViewHeader.h
//  Zebra
//
//  Created by Wilson Styres on 1/18/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZBBoldHeaderView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBBoldCollectionViewHeader : UICollectionReusableView
@property (nonatomic) ZBBoldHeaderView *headerView;
- (UILabel *)titleLabel;
- (UIButton *)actionButton;
@end

NS_ASSUME_NONNULL_END
