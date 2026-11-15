//
//  ZBLiveSearchResultTableViewCell.h
//  Zebra
//
//  Created by Andrew Abosh on 2020-03-29.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBProxyPackage.h"
NS_ASSUME_NONNULL_BEGIN

@interface ZBLiveSearchResultTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *packageIconImageView;
@property (strong, nonatomic) IBOutlet UILabel *packageNameLabel;
@property (strong, nonatomic) IBOutlet UIImageView *isPaidImageView;
@property (strong, nonatomic) IBOutlet UIImageView *isInstalledImageView;
- (void)updateData:(ZBProxyPackage *)package;
- (void)setColors;
@end

NS_ASSUME_NONNULL_END
