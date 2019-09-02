//
//  ZBFootnotesTableViewCell.h
//  Zebra
//
//  Created by Andrew Abosh on 2019-09-02.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBFootnotesTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *creditsButton;
@property (weak, nonatomic) IBOutlet UILabel *deviceInfoLabel;

@end

NS_ASSUME_NONNULL_END
