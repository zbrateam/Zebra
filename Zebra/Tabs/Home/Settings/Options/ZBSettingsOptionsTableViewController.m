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

@synthesize footerText;
@synthesize options;
@synthesize selectedRow;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(self.navigationItem.title, @"");
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section_ {
    return options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"settingsOptionsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.text = NSLocalizedString(options[indexPath.row], @"");
    cell.accessoryType = selectedRow == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.tintColor = [UIColor tintColor];
    cell.textLabel.textColor = [UIColor primaryTextColor];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSMutableArray *localize = [NSMutableArray new];
    for (NSString *string in footerText) {
        [localize addObject:NSLocalizedString(string, @"")];
    }
    return [localize componentsJoinedByString:@"\n\n"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    if (selectedRow != indexPath.row) {
        selectedRow = indexPath.row;
        if (_settingChanged) {
            _settingChanged(indexPath.row);
        }
        [self.tableView reloadData];
    }
}

@end
