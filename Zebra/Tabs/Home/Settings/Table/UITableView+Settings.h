//
//  UITableView+Settings.h
//  Zebra
//
//  Created by absidue on 20-06-27.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewCell.h"
#import "ZBSwitchSettingsTableViewCell.h"
#import "ZBButtonSettingsTableViewCell.h"
#import "ZBLinkSettingsTableViewCell.h"
#import "ZBDetailedLinkSettingsTableViewCell.h"
#import "ZBOptionSettingsTableViewCell.h"
#import "ZBOptionSubtitleSettingsTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    ZBSettingsCell,
    ZBSwitchSettingsCell,
    ZBButtonSettingsCell,
    ZBLinkSettingsCell,
    ZBDetailedLinkSettingsCell,
    ZBOptionSettingsCell,
    ZBOptionSubtitleSettingsCell,
} ZBSettingsCells;

@interface UITableView (Settings)

- (void)registerCellType:(ZBSettingsCells)type;
- (void)registerCellTypes:(NSArray<NSNumber *> *)types;
- (ZBSettingsTableViewCell *)dequeueSettingsCellForIndexPath:(NSIndexPath *)indexPath;
- (ZBSwitchSettingsTableViewCell *)dequeueSwitchSettingsCellForIndexPath:(NSIndexPath *)indexPath;
- (ZBButtonSettingsTableViewCell *)dequeueButtonSettingsCellForIndexPath:(NSIndexPath *)indexPath;
- (ZBLinkSettingsTableViewCell *)dequeueLinkSettingsCellForIndexPath:(NSIndexPath *)indexPath;
- (ZBDetailedLinkSettingsTableViewCell *)dequeueDetailedLinkSettingsCellForIndexPath:(NSIndexPath *)indexPath;
- (ZBOptionSettingsTableViewCell *)dequeueOptionSettingsCellForIndexPath:(NSIndexPath *)indexPath;
- (ZBOptionSubtitleSettingsTableViewCell *)dequeueOptionSubtitleSettingsCellForIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
