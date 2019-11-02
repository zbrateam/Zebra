//
//  ZBSettingsGraphicsModeTableViewController.m
//  Zebra
//
//  Created by Louis on 02/11/2019.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//


#import "ZBSettingsGraphicsModeTableViewController.h"
#import <ZBSettings.h>

@interface ZBSettingsGraphicsModeTableViewController () {
    ZBModeSelection selectedMode;
}

@end

@implementation ZBSettingsGraphicsModeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Dark Mode", @"");
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    [self configureSelectedMode];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.tableView reloadData];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
}

- (void)configureSelectedMode {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:thirteenModeKey]) {
        selectedMode = ZBThirteen;
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:oledModeKey]) {
        selectedMode = ZBOled;
    } else {
        selectedMode = ZBDefaultMode;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section_ {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"settingsGraphicsModeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Default", @"");
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"OLED", @"");
    } else if (indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedString(@"iOS 13", @"");
    } else {
        cell.textLabel.text = @"";
    }
    if (self->selectedMode == indexPath.row) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    [cell setTintColor: [UIColor tintColor]];
    cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    selectedMode = (ZBModeSelection)indexPath.row;
    [defaults setBool:selectedMode == ZBThirteen forKey:thirteenModeKey];
    [defaults setBool:selectedMode == ZBOled forKey:oledModeKey];
    [defaults synchronize];
    [ZBDevice hapticButton];
    [self.tableView reloadData];
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    [ZBDevice darkModeEnabled] ? [ZBDevice configureDarkMode] : [ZBDevice configureLightMode];
    [ZBDevice refreshViews];
    [self setNeedsStatusBarAppearanceUpdate];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"darkMode" object:self];
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionFade;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.fillMode = kCAFillModeForwards;
    transition.duration = 0.35;
    transition.subtype = kCATransitionFromTop;
    [self.view.layer addAnimation:transition forKey:nil];
    [self.navigationController.navigationBar.layer addAnimation:transition forKey:nil];
}

@end
