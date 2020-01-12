//
//  ZBSettingsDisplayTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSettingsDisplayTableViewController.h"
#import <ZBSettings.h>
#import <UIColor+GlobalColors.h>

typedef NS_ENUM(NSInteger, ZBSectionOrder) {
    ZBSectionAccentColor,
    ZBSectionSystemStyle,
    ZBSectionStyleChooser,
    ZBSectionPureBlack,
};

@interface ZBSettingsDisplayTableViewController () {
    BOOL useSystemStyle;
    BOOL pureBlack;
    ZBAccentColor accentColor;
}
@end

@implementation ZBSettingsDisplayTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Display", @"");
    
    useSystemStyle = YES;
    pureBlack = NO;
    accentColor = [ZBSettings accentColor];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (useSystemStyle) {
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
            if (!useSystemStyle) return 2;
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
                case ZBAccentColorBlue:
                    cell.detailTextLabel.text = NSLocalizedString(@"Blue", @"");
                    break;
                case ZBAccentColorOrange:
                    cell.detailTextLabel.text = NSLocalizedString(@"Orange", @"");
                    break;
                case ZBAccentColorAdaptive:
                    cell.detailTextLabel.text = NSLocalizedString(@"Adaptive", @"");
                    break;
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = NSLocalizedString(@"Accent Color", @"");
            break;
        }
        case ZBSectionSystemStyle: {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = @"Use System Style";
            
            UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [enableSwitch addTarget:self action:@selector(toggleSystemStyle:) forControlEvents:UIControlEventValueChanged];
            [enableSwitch setOnTintColor:[UIColor tintColor]];
            
            enableSwitch.on = useSystemStyle;
            cell.accessoryView = enableSwitch;
            break;
        }
        case ZBSectionStyleChooser: {
            if (!useSystemStyle) {
                if (indexPath.row == 0) {
                    cell.textLabel.text = @"Light";
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else {
                    cell.textLabel.text = @"Dark";
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
            
            enableSwitch.on = pureBlack;
            cell.accessoryView = enableSwitch;
            break;
        }
    }
    
    return cell;
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

- (void)toggleSystemStyle:(id)sender {
    useSystemStyle = !useSystemStyle;
    
    if (!useSystemStyle) {
        [self.tableView beginUpdates];
        [self.tableView insertSections:[[NSIndexSet alloc] initWithIndex:ZBSectionStyleChooser] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
    else {
        [self.tableView beginUpdates];
        [self.tableView deleteSections:[[NSIndexSet alloc] initWithIndex:ZBSectionStyleChooser] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

- (void)togglePureBlack:(id)sender {
    pureBlack = !pureBlack;
}


@end
