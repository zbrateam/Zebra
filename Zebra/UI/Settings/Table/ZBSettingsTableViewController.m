//
//  ZBSettingsTableViewController.m
//  Zebra
//
//  Created by absidue on 20-06-22.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewController.h"
#import "ZBSwitchSettingsTableViewCell.h"
#import "ZBOptionSettingsTableViewCell.h"
#import "ZBDevice.h"

@implementation ZBSettingsTableViewController

#pragma mark - Table view methods

- (instancetype)init {
    if (@available(iOS 13.0, *)) {
        self = [super initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [super initWithStyle:UITableViewStyleGrouped];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (@available(iOS 13.0, *)) {
        self = [super initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [super initWithStyle:UITableViewStyleGrouped];
    }
    return self;
}

#pragma mark - Settings cell action helpers

- (void)toggleSwitchAtIndexPath:(NSIndexPath *)indexPath {
    ZBSwitchSettingsTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell toggle];
}

- (void)chooseOptionAtIndexPath:(NSIndexPath *)indexPath previousIndexPath:(NSIndexPath *)previousIndexPath animated:(BOOL)animated {
    if (animated) {
        [self.tableView reloadRowsAtIndexPaths:@[previousIndexPath, indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        ZBOptionSettingsTableViewCell *cell = [self.tableView cellForRowAtIndexPath:previousIndexPath];
        [cell setChosen:NO];
        
        cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [cell setChosen:NO];
    }
    [ZBDevice hapticButton];
}

- (void)chooseUnchooseOptionAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [ZBDevice hapticButton];
}

@end
