//
//  ZBSettingsDisplayTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSettingsDisplayTableViewController.h"
#import "ZBSettingsOptionsTableViewController.h"
#import <ZBSettings.h>
#import <UIColor+GlobalColors.h>

typedef NS_ENUM(NSInteger, ZBSectionOrder) {
    ZBSectionAccentColor,
    ZBSectionSystemStyle,
    ZBSectionStyleChooser,
    ZBSectionPureBlack,
};

@interface ZBSettingsDisplayTableViewController () {
    BOOL usesSystemAppearance;
    BOOL pureBlackMode;
    ZBAccentColor accentColor;
    ZBInterfaceStyle interfaceStyle;
}
@end

@implementation ZBSettingsDisplayTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Display", @"");
    
    accentColor = [ZBSettings accentColor];
    usesSystemAppearance = [ZBSettings usesSystemAppearance];
    interfaceStyle = [ZBSettings interfaceStyle];
    pureBlackMode = [ZBSettings pureBlackMode];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (usesSystemAppearance) {
        return 3;
    }
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case ZBSectionAccentColor:
        case ZBSectionSystemStyle:
            return 1;
        case ZBSectionStyleChooser:
            if (!usesSystemAppearance) return 2;
        case ZBSectionPureBlack:
            return 1;
        default:
            return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"displayCell"];
    
    ZBSectionOrder section = indexPath.section;
    switch (section) {
        case ZBSectionAccentColor: {
            switch (accentColor) {
                case ZBAccentColorCornflowerBlue:
                    cell.detailTextLabel.text = NSLocalizedString(@"Cornflower Blue", @"");
                    break;
                case ZBAccentColorSystemBlue:
                    cell.detailTextLabel.text = NSLocalizedString(@"System Blue", @"");
                    break;
                case ZBAccentColorOrange:
                    cell.detailTextLabel.text = NSLocalizedString(@"Orange", @"");
                    break;
                case ZBAccentColorAdaptive:
                    cell.detailTextLabel.text = NSLocalizedString(@"Adaptive", @"");
                    break;
            }

            cell.imageView.image = [self getCircularImage:CGSizeMake(16, 16) color:[UIColor getTintColor:accentColor]];
            cell.imageView.layer.cornerRadius = cell.imageView.image.size.width / 2;
            cell.imageView.layer.masksToBounds = YES;
                        
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = NSLocalizedString(@"Accent Color", @"");
            break;
        }
        case ZBSectionSystemStyle: {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = @"Use System Appearance";
            
            UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [enableSwitch addTarget:self action:@selector(toggleSystemStyle:) forControlEvents:UIControlEventValueChanged];
            [enableSwitch setOnTintColor:[UIColor tintColor]];
            
            enableSwitch.on = usesSystemAppearance;
            cell.accessoryView = enableSwitch;
            break;
        }
        case ZBSectionStyleChooser: {
            if (!usesSystemAppearance) {
                if (indexPath.row == 0) {
                    cell.textLabel.text = @"Light";
                    cell.accessoryType = interfaceStyle == ZBInterfaceStyleLight ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                }
                else {
                    cell.textLabel.text = @"Dark";
                    cell.accessoryType = interfaceStyle == ZBInterfaceStyleDark || interfaceStyle == ZBInterfaceStylePureBlack ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                }
                break;
            }
        }
        case ZBSectionPureBlack: {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = @"Pure Black Mode";
            
            UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [enableSwitch addTarget:self action:@selector(togglePureBlack:) forControlEvents:UIControlEventValueChanged];
            [enableSwitch setOnTintColor:[UIColor tintColor]];
            
            enableSwitch.on = pureBlackMode;
            cell.accessoryView = enableSwitch;
            break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    ZBSectionOrder section = indexPath.section;
    switch (section) {
        case ZBSectionAccentColor:
            [self changeTint];
            break;
        case ZBSectionStyleChooser: {
            if (!usesSystemAppearance) {
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                UITableViewCell *otherCell;
                
                if (indexPath.row == 0) { //Light
                    otherCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:ZBSectionStyleChooser]];
                    
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    otherCell.accessoryType = UITableViewCellAccessoryNone;
                    
                    interfaceStyle = ZBInterfaceStyleLight;
                    [ZBSettings setInterfaceStyle:ZBInterfaceStyleLight];
                }
                else { //Dark
                    otherCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:ZBSectionStyleChooser]];
                    
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
                [self updateInterfaceStyle];
            }
        }
        default:
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ZBSectionSystemStyle:
            return @"Appearance";
        default:
            return NULL;
    }
}

#pragma mark - Settings

- (void)changeTint {
    ZBSettingsOptionsTableViewController * controller = [[ZBSettingsOptionsTableViewController alloc] initWithStyle: UITableViewStyleGrouped];
    controller.title = @"Accent Color";
    controller.footerText = @[@"Change the accent color that displays across Zebra."];
    controller.options = @[@"Cornflower Blue", @"System Blue", @"Orange", @"Adaptive"];
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:tintSelectionKey];
    controller.selectedRow = number ? (ZBAccentColor)[number integerValue] : ZBAccentColorCornflowerBlue;
    controller.settingChanged = ^(NSInteger newValue) {
        ZBAccentColor color = (ZBAccentColor)newValue;
        [ZBSettings setAccentColor:color];
    };
    [self.navigationController pushViewController: controller animated:YES];
}

- (void)toggleSystemStyle:(UISwitch *)sender {
    BOOL setting = sender.on;
    
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
    
    [ZBSettings updateInterfaceStyle];
}

- (UIImage*)getCircularImage:(CGSize)size color:(UIColor*)color {
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    [color setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
