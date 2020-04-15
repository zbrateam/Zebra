//
//  ZBDisplaySettingsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBDisplaySettingsTableViewController.h"
//#import "ZBSettingsSelectionTableViewController.h"
#import <ZBSettings.h>
#import <UIColor+GlobalColors.h>
#import <ZBThemeManager.h>
#import "Accent Color/ZBAccentColorTableViewController.h"

typedef NS_ENUM(NSInteger, ZBSectionOrder) {
    ZBSectionAccentColor,
    ZBSectionSystemStyle,
    ZBSectionStyleChooser,
    ZBSectionPureBlack,
};

@interface ZBDisplaySettingsTableViewController () {
    BOOL usesSystemAppearance;
    BOOL pureBlackMode;
    ZBAccentColor accentColor;
    ZBInterfaceStyle interfaceStyle;
}
@end

@implementation ZBDisplaySettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Display", @"");
    
    accentColor = [ZBSettings accentColor];
    usesSystemAppearance = [ZBSettings usesSystemAppearance];
    interfaceStyle = [ZBSettings interfaceStyle];
    pureBlackMode = [ZBSettings pureBlackMode];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRightIconTableViewCell" bundle:nil] forCellReuseIdentifier:@"settingsColorCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    accentColor = [ZBSettings accentColor];
    usesSystemAppearance = [ZBSettings usesSystemAppearance];
    interfaceStyle = [ZBSettings interfaceStyle];
    pureBlackMode = [ZBSettings pureBlackMode];
    
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (@available(iOS 13.0, *)) {
        if (usesSystemAppearance) {
            return 3;
        }
        return 4;
    }
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case ZBSectionAccentColor:
            return 1;
        case ZBSectionSystemStyle:
            if (@available(iOS 13.0, *)) return 1;
        case ZBSectionStyleChooser:
            if (@available(iOS 13.0, *)) {
                if (!usesSystemAppearance) return 2;
            }
            else if (section == 1 && !usesSystemAppearance) return 2;
        case ZBSectionPureBlack:
            return 1;
        default:
            return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settingsDisplayCell"];
    
    ZBSectionOrder section = indexPath.section;
    switch (section) {
        case ZBSectionAccentColor: {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"colorCell"];
            cell.textLabel.text = NSLocalizedString(@"Accent Color", @"");
            cell.detailTextLabel.text = [ZBThemeManager localizedNameForAccentColor:[ZBSettings accentColor]];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case ZBSectionSystemStyle: {
            if (@available(iOS 13.0, *)) {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.text = NSLocalizedString(@"Use System Appearance", @"");
                
                UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
                [enableSwitch addTarget:self action:@selector(toggleSystemStyle:) forControlEvents:UIControlEventValueChanged];
                [enableSwitch setOnTintColor:[UIColor accentColor]];
                
                enableSwitch.on = usesSystemAppearance;
                cell.accessoryView = enableSwitch;
                break;
            }
        }
        case ZBSectionStyleChooser: {
            if (@available(iOS 13.0, *)) {
                if (!usesSystemAppearance) {
                    if (indexPath.row == 0) {
                        cell.textLabel.text = NSLocalizedString(@"Light", @"");
                        cell.accessoryType = interfaceStyle == ZBInterfaceStyleLight ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    }
                    else {
                        cell.textLabel.text = NSLocalizedString(@"Dark", @"");
                        cell.accessoryType = interfaceStyle == ZBInterfaceStyleDark || interfaceStyle == ZBInterfaceStylePureBlack ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    }
                    break;
                }
            }
            else if (indexPath.section == 1) {
                if (indexPath.row == 0) {
                    cell.textLabel.text = NSLocalizedString(@"Light", @"");
                    cell.accessoryType = interfaceStyle == ZBInterfaceStyleLight ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                }
                else {
                    cell.textLabel.text = NSLocalizedString(@"Dark", @"");
                    cell.accessoryType = interfaceStyle == ZBInterfaceStyleDark || interfaceStyle == ZBInterfaceStylePureBlack ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                }
                break;
            }
        }
        case ZBSectionPureBlack: {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = NSLocalizedString(@"Pure Black Mode", @"");
            
            UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [enableSwitch addTarget:self action:@selector(togglePureBlack:) forControlEvents:UIControlEventValueChanged];
            [enableSwitch setOnTintColor:[UIColor accentColor]];
            
            enableSwitch.on = pureBlackMode;
            cell.accessoryView = enableSwitch;
            break;
        }
    }
    cell.textLabel.textColor = [UIColor primaryTextColor];
    cell.backgroundColor = [UIColor cellBackgroundColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ZBSectionOrder section = indexPath.section;
    switch (section) {
        case ZBSectionAccentColor:
            [self changeTint];
            break;
        case ZBSectionSystemStyle: {
            if (@available(iOS 13.0, *)) {
                break;
            }
        }
        case ZBSectionStyleChooser: {
            if (!usesSystemAppearance) {
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                UITableViewCell *otherCell;
                
                if (indexPath.row == 0) { //Light
                    if (@available(iOS 13.0, *)) {
                        otherCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:ZBSectionStyleChooser]];
                    }
                    else {
                        otherCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:ZBSectionSystemStyle]];
                    }
                    
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    otherCell.accessoryType = UITableViewCellAccessoryNone;
                    
                    interfaceStyle = ZBInterfaceStyleLight;
                    [ZBSettings setInterfaceStyle:ZBInterfaceStyleLight];
                }
                else { //Dark
                    if (@available(iOS 13.0, *)) {
                        otherCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:ZBSectionStyleChooser]];
                    }
                    else {
                        otherCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:ZBSectionSystemStyle]];
                    }
                    
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    otherCell.accessoryType = UITableViewCellAccessoryNone;
                    
                    if (pureBlackMode) {
                        interfaceStyle = ZBInterfaceStylePureBlack;
                        [ZBSettings setInterfaceStyle:ZBInterfaceStylePureBlack];
                    }
                    else {
                        interfaceStyle = ZBInterfaceStyleDark;
                        [ZBSettings setInterfaceStyle:ZBInterfaceStyleDark];
                    }
                }
                cell.tintColor = [UIColor accentColor];
                self.navigationController.navigationBar.tintColor = [UIColor accentColor];
                [self updateInterfaceStyle];
            }
        }
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.tintColor = [UIColor accentColor];
    cell.backgroundColor = [UIColor cellBackgroundColor];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ZBSectionSystemStyle:
            return NSLocalizedString(@"Appearance", @"");
        default:
            return NULL;
    }
}

#pragma mark - Settings

- (void)changeTint {
    ZBAccentColorTableViewController *controller = [[ZBAccentColorTableViewController alloc] init];

    [self.navigationController pushViewController:controller animated:YES];
}

- (void)toggleSystemStyle:(UISwitch *)sender {
    BOOL setting = sender.on;
    
    usesSystemAppearance = setting;
    [ZBSettings setUsesSystemAppearance:setting];
    
    [self updateInterfaceStyle];
    
    if (!setting) { //Insert style picker section
        [self.tableView beginUpdates];
        [self.tableView insertSections:[[NSIndexSet alloc] initWithIndex:ZBSectionStyleChooser] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
    else { //Delete style picker section
        [self.tableView beginUpdates];
        [self.tableView deleteSections:[[NSIndexSet alloc] initWithIndex:ZBSectionStyleChooser] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

- (void)togglePureBlack:(UISwitch *)sender {
    BOOL setting = sender.on;
    
    pureBlackMode = setting;
    [ZBSettings setPureBlackMode:setting];
    [self updateInterfaceStyle];
}

- (void)updateInterfaceStyle {
    usesSystemAppearance = [ZBSettings usesSystemAppearance];
    interfaceStyle = [ZBSettings interfaceStyle];
    
    [[ZBThemeManager sharedInstance] updateInterfaceStyle];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    }];
}

@end
