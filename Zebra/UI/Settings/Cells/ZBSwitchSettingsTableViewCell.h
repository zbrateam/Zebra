//
//  ZBSwitchSettingsTableViewCell.h
//  Zebra
//
//  Created by absidue on 20-06-14.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBSwitchSettingsTableViewCell : ZBSettingsTableViewCell

- (void)setTarget:(id)target action:(SEL)action;
- (void)setOn:(BOOL)on; // doesn't send action
- (void)toggle;
- (BOOL)isOn;

@end

NS_ASSUME_NONNULL_END
