//
//  ZBOptionSettingsTableViewCell.h
//  Zebra
//
//  Created by absidue on 20-06-20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBOptionSettingsTableViewCell : ZBSettingsTableViewCell

- (void)setChosen:(BOOL)chosen;
- (BOOL)isChosen;

@end

NS_ASSUME_NONNULL_END
