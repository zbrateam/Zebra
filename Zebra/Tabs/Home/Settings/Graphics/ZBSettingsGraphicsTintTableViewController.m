//
//  ZBSettingsGraphicsTintTableViewController.m
//  Zebra
//
//  Created by Louis on 02/11/2019.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSettingsGraphicsTintTableViewController.h"
#import <ZBSettings.h>

@interface ZBSettingsGraphicsTintTableViewController () {
    ZBTintSelection tintColorType;
}

@end

@implementation ZBSettingsGraphicsTintTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Tint Color", @"");
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    [self configureSelectedTint];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.tableView reloadData];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
}

- (void)configureSelectedTint {
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:tintSelectionKey];
    if (number) {
        tintColorType = (ZBTintSelection)[number integerValue];
    } else {
        tintColorType = ZBDefaultTint;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section_ {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"settingsGraphicsTintCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Default", @"");
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"Blue", @"");
    } else if (indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedString(@"Orange", @"");
    } else if (indexPath.row == 3) {
        if (ZBDevice.darkModeEnabled) {
            cell.textLabel.text = NSLocalizedString(@"White", @"");
        } else {
            cell.textLabel.text = NSLocalizedString(@"Black", @"");
        }
    } else {
        cell.textLabel.text = @"";
    }
    if (self->tintColorType == indexPath.row) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    [cell setTintColor: [UIColor tintColor]];
    cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    tintColorType = (ZBTintSelection) indexPath.row;
    [[NSUserDefaults standardUserDefaults] setObject:@(tintColorType) forKey:tintSelectionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [ZBDevice hapticButton];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"darkMode" object:self];
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.tableView reloadData];
        [ZBDevice darkModeEnabled] ? [ZBDevice configureDarkMode] : [ZBDevice configureLightMode];
        [ZBDevice refreshViews];
        [self setNeedsStatusBarAppearanceUpdate];
    } completion:nil];
}

@end
