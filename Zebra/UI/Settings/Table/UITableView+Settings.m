//
//  UITableView+Settings.m
//  Zebra
//
//  Created by absidue on 20-06-27.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "UITableView+Settings.h"

@implementation UITableView (Settings)

- (void)registerCellType:(ZBSettingsCells)type {
    switch (type) {
        case ZBSettingsCell:
            [self registerClass:[ZBSettingsTableViewCell class] forCellReuseIdentifier:@"settingsCell"];
            break;
        case ZBSwitchSettingsCell:
            [self registerClass:[ZBSwitchSettingsTableViewCell class] forCellReuseIdentifier:@"settingsSwitchCell"];
            break;
        case ZBButtonSettingsCell:
            [self registerClass:[ZBButtonSettingsTableViewCell class] forCellReuseIdentifier:@"settingsButtonCell"];
            break;
        case ZBLinkSettingsCell:
            [self registerClass:[ZBLinkSettingsTableViewCell class] forCellReuseIdentifier:@"settingsLinkCell"];
            break;
        case ZBDetailedLinkSettingsCell:
            [self registerClass:[ZBDetailedLinkSettingsTableViewCell class] forCellReuseIdentifier:@"settingsDetailedLinkCell"];
            break;
        case ZBOptionSettingsCell:
            [self registerClass:[ZBOptionSettingsTableViewCell class] forCellReuseIdentifier:@"settingsOptionCell"];
            break;
        case ZBOptionSubtitleSettingsCell:
            [self registerClass:[ZBOptionSubtitleSettingsTableViewCell class] forCellReuseIdentifier:@"settingsOptionSubtitleCell"];
            break;
        default:
            break;
    }
}

- (void)registerCellTypes:(NSArray<NSNumber *> *)types {
    NSSet *depuplicatedTypes = [NSSet setWithArray:types];
    for (NSNumber *type in depuplicatedTypes) {
        [self registerCellType:[type unsignedIntegerValue]];
    }
}

- (ZBSettingsTableViewCell *)dequeueSettingsCellForIndexPath:(NSIndexPath *)indexPath {
    return [self dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:indexPath];
}

- (ZBSwitchSettingsTableViewCell *)dequeueSwitchSettingsCellForIndexPath:(NSIndexPath *)indexPath {
    return [self dequeueReusableCellWithIdentifier:@"settingsSwitchCell" forIndexPath:indexPath];
}

- (ZBButtonSettingsTableViewCell *)dequeueButtonSettingsCellForIndexPath:(NSIndexPath *)indexPath {
    return [self dequeueReusableCellWithIdentifier:@"settingsButtonCell" forIndexPath:indexPath];
}

- (ZBLinkSettingsTableViewCell *)dequeueLinkSettingsCellForIndexPath:(NSIndexPath *)indexPath {
    return [self dequeueReusableCellWithIdentifier:@"settingsLinkCell" forIndexPath:indexPath];
}

- (ZBDetailedLinkSettingsTableViewCell *)dequeueDetailedLinkSettingsCellForIndexPath:(NSIndexPath *)indexPath {
    return [self dequeueReusableCellWithIdentifier:@"settingsDetailedLinkCell" forIndexPath:indexPath];
}

- (ZBOptionSettingsTableViewCell *)dequeueOptionSettingsCellForIndexPath:(NSIndexPath *)indexPath {
    return [self dequeueReusableCellWithIdentifier:@"settingsOptionCell" forIndexPath:indexPath];
}

- (ZBOptionSubtitleSettingsTableViewCell *)dequeueOptionSubtitleSettingsCellForIndexPath:(NSIndexPath *)indexPath {
    return [self dequeueReusableCellWithIdentifier:@"settingsOptionSubtitleCell" forIndexPath:indexPath];
}

@end
