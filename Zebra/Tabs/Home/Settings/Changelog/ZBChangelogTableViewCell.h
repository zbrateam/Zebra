//
//  ZBChangelogTableViewCell.h
//  Zebra
//
//  Created by Wilson Styres on 8/27/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBChangelogTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UILabel *detailsLabel;

@end

NS_ASSUME_NONNULL_END
