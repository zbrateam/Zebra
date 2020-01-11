//
//  ZBSettingsGraphicsTintTableViewController.m
//  Zebra
//
//  Created by Louis on 02/11/2019.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSettingsOptionsTableViewController.h"
#import <ZBSettings.h>

@implementation ZBSettingsOptionsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(self.settingTitle, @"");
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.tableView reloadData];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section_ {
    return _settingOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"settingsOptionsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.text = NSLocalizedString(_settingOptions[indexPath.row], @"");
    cell.accessoryType = _settingSelectedRow == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.tintColor = [UIColor tintColor];
    cell.textLabel.textColor = [UIColor primaryTextColor];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSMutableArray *localize = [NSMutableArray new];
    for (NSString *string in self.settingFooter) {
        [localize addObject:NSLocalizedString(string, @"")];
    }
    return [localize componentsJoinedByString:@"\n\n"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    if (_settingSelectedRow != indexPath.row) {
        _settingSelectedRow = indexPath.row;
        if (_settingChanged) {
            _settingChanged(indexPath.row);
        }
        [self.tableView reloadData];
    }
}

@end
