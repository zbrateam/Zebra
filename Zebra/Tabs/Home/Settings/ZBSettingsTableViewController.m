//
//  SettingsTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewController.h"
#import "ZBSettingsOptionsTableViewController.h"
#import <ZBSettings.h>
#import <Queue/ZBQueue.h>
#import "UIImageView+Zebra.h"
#import "ZBAppIconTableViewCell.h"
#import "ZBSettingsDisplayTableViewController.h"

typedef NS_ENUM(NSInteger, ZBSectionOrder) {
    ZBInterface,
    ZBFeatured,
    ZBNews,
    ZBSearch,
    ZBMisc,
    ZBAdvanced
};

typedef NS_ENUM(NSUInteger, ZBInterfaceOrder) {
    ZBDisplay,
    ZBAppIcon
};

typedef NS_ENUM(NSUInteger, ZBFeatureOrder) {
    ZBFeaturedEnable,
    ZBFeatureOrRandomToggle,
    ZBFeatureBlacklist
};

typedef NS_ENUM(NSUInteger, ZBAdvancedOrder) {
    ZBDropTables,
    ZBOpenDocs,
    ZBClearImageCache,
    ZBClearKeychain
};

enum ZBMiscOrder {
    ZBIconAction
};

@interface ZBSettingsTableViewController () {
    NSMutableDictionary *_colors;
    ZBAccentColor accentColor;
    ZBInterfaceStyle interfaceStyle;
}

@end

@implementation ZBSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Settings", @"");
    
    accentColor = [ZBSettings accentColor];
    interfaceStyle = [ZBSettings interfaceStyle];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBAppIconTableViewCell" bundle:nil] forCellReuseIdentifier:@"settingsAppIconCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (IBAction)closeButtonTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section_ {
    ZBSectionOrder section = section_;
    switch (section) {
        case ZBFeatured:
            return NSLocalizedString(@"Home", @"");
        case ZBNews:
            return NSLocalizedString(@"Changes", @"");
        case ZBSearch:
            return NSLocalizedString(@"Search", @"");
        case ZBMisc:
            return NSLocalizedString(@"Miscellaneous", @"");
        case ZBAdvanced:
            return NSLocalizedString(@"Advanced", @"");
        default:
            return NULL;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section_ {
    ZBSectionOrder section = section_;
    switch (section) {
        case ZBNews:
        case ZBMisc:
        case ZBSearch:
            return 1;
        case ZBInterface:
            if (@available(iOS 10.3, *)) {
                return 2;
            }
            return 1;
        case ZBFeatured: {
            int rows = 1;
            BOOL wantsFeatured = [[NSUserDefaults standardUserDefaults] boolForKey:wantsFeaturedKey];
            if (wantsFeatured) {
                BOOL randomFeatured = [[NSUserDefaults standardUserDefaults] boolForKey:randomFeaturedKey];
                if (randomFeatured) {
                    return 3;
                }
                return 2;
            }
            
            return rows;
        }
        case ZBAdvanced:
            return 4;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == ZBInterface && indexPath.row == ZBAppIcon) {
        if (@available(iOS 10.3, *)) {
            ZBAppIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsAppIconCell"];
            
            cell.label.text = @"App Icon";
            
            NSDictionary *icon = [ZBAlternateIconController iconForName:[[UIApplication sharedApplication] alternateIconName]];
            UIImage *iconImage = [UIImage imageNamed:[icon objectForKey:@"iconName"]];
            [cell setIcon:iconImage border:[[icon objectForKey:@"border"] boolValue]];
            
            return cell;
        }
    }
    else if ((indexPath.section == ZBFeatured && indexPath.row == ZBFeatureOrRandomToggle) || indexPath.section == ZBMisc) {
        static NSString *cellIdentifier = @"settingsRightDetailCell";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        }
    } else {
        static NSString *cellIdentifier = @"settingsCell";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
    }
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.imageView.image = nil;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryNone;
    ZBSectionOrder section = indexPath.section;
    switch (section) {
        case ZBInterface: {
            ZBInterfaceOrder row = indexPath.row;
            switch (row) {
                case ZBDisplay: {
                    cell.textLabel.text = NSLocalizedString(@"Display", @"");
                    break;
                }
                case ZBAppIcon: {
                    cell.textLabel.text = NSLocalizedString(@"App Icon", @"");
                    if (@available(iOS 10.3, *)) {
                        NSDictionary *icon = [ZBAlternateIconController iconForName:[[UIApplication sharedApplication] alternateIconName]];
                        
                        cell.detailTextLabel.text = [icon objectForKey:@"shortName"];
                        
                        cell.imageView.image = [UIImage imageNamed:[icon objectForKey:@"iconName"]];
                        [cell.imageView resize:CGSizeMake(30, 30) applyRadius:true];
                        
                        if ([[icon objectForKey:@"border"] boolValue]) {
                            [cell.imageView applyBorder];
                        }
                        else {
                            [cell.imageView removeBorder];
                        }
                    }
                    break;
                }
            }
            
            cell.textLabel.textColor = [UIColor primaryTextColor];
            cell.detailTextLabel.textColor = [UIColor secondaryTextColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
        }
        case ZBFeatured: {
            ZBFeatureOrder row = indexPath.row;
            switch (row) {
                case ZBFeaturedEnable: {
                    UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
                    enableSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:wantsFeaturedKey];
                    [enableSwitch addTarget:self action:@selector(toggleFeatured:) forControlEvents:UIControlEventValueChanged];
                    [enableSwitch setOnTintColor:[UIColor tintColor]];
                    cell.accessoryView = enableSwitch;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.textLabel.text = NSLocalizedString(@"Featured Packages", @"");
                    break;
                }
                case ZBFeatureOrRandomToggle: {
                    NSInteger selected = [[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:randomFeaturedKey]] integerValue];

                    if (selected == 0) {
                        cell.detailTextLabel.text = NSLocalizedString(@"Repo Featured", @"");
                    } else {
                        cell.detailTextLabel.text = NSLocalizedString(@"Random", @"");
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.textLabel.text = NSLocalizedString(@"Feature Type", @"");
                    break;
                }
                case ZBFeatureBlacklist: {
                    cell.textLabel.text = NSLocalizedString(@"Select Repos to be Featured", @"");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
            }
            cell.textLabel.textColor = [UIColor primaryTextColor];
            return cell;
        }
        case ZBNews: {
            UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            enableSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:wantsNewsKey];
            [enableSwitch addTarget:self action:@selector(toggleNews:) forControlEvents:UIControlEventValueChanged];
            [enableSwitch setOnTintColor:[UIColor tintColor]];
            cell.accessoryView = enableSwitch;
            cell.textLabel.text = NSLocalizedString(@"Community News", @"");
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.textColor = [UIColor primaryTextColor];
            return cell;
        }
        case ZBSearch: {
            UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            enableSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:liveSearchKey];
            [enableSwitch addTarget:self action:@selector(toggleLiveSearch:) forControlEvents:UIControlEventValueChanged];
            [enableSwitch setOnTintColor:[UIColor tintColor]];
            cell.accessoryView = enableSwitch;
            cell.textLabel.text = NSLocalizedString(@"Live Search", @"");
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.textColor = [UIColor primaryTextColor];
            return cell;
        }
        case ZBMisc: {
            NSString *text = nil;
            if (indexPath.row == ZBIconAction) {
                text = NSLocalizedString(@"Swipe Actions Display As", @"");
                NSInteger selected = [[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:iconActionKey]] integerValue];
                if (selected == 0) {
                    cell.detailTextLabel.text = NSLocalizedString(@"Text", @"");
                } else {
                    cell.detailTextLabel.text = NSLocalizedString(@"Icon", @"");
                }
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.textColor = [UIColor primaryTextColor];
            }
            cell.textLabel.text = text;
            return cell;
        }
        case ZBAdvanced: {
            NSString *text = nil;
            if (indexPath.row == ZBDropTables) {
                text = NSLocalizedString(@"Drop Tables", @""); // This should probably not be localized since DROP TABLE is a SQL thing
            } else if (indexPath.row == ZBOpenDocs) {
                text = NSLocalizedString(@"Open Documents Directory", @"");
            } else if (indexPath.row == ZBClearImageCache) {
                text = NSLocalizedString(@"Clear Image Cache", @"");
            } else if (indexPath.row == ZBClearKeychain) {
                text = NSLocalizedString(@"Clear Keychain", @"");
            }
            cell.textLabel.text = text;
            cell.textLabel.textColor = [UIColor tintColor];
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSectionOrder section = indexPath.section;
    switch (section) {
        case ZBInterface: {
            ZBInterfaceOrder row = indexPath.row;
            switch (row) {
                case ZBDisplay:
                    [self displaySettings];
                    break;
                case ZBAppIcon:
                    [self changeIcon];
                    break;
            }
            break;
        }
        case ZBFeatured: {
            ZBFeatureOrder row = indexPath.row;
            switch (row) {
                case ZBFeaturedEnable:
                    [self getTappedSwitch:indexPath];
                    break;
                case ZBFeatureOrRandomToggle:
                    [self featureOrRandomToggle];
                    break;
                case ZBFeatureBlacklist:
                    [self openBlackList];
                    break;
                default:
                    break;
            }
            break;
        }
        case ZBNews: {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UISwitch *switcher = (UISwitch *)cell.accessoryView;
            [switcher setOn:!switcher.on animated:YES];
            [self toggleNews:switcher];
            break;
        }
        case ZBMisc: {
            [self misc];
            break;
        }
        case ZBSearch: {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UISwitch *switcher = (UISwitch *)cell.accessoryView;
            [switcher setOn:!switcher.on animated:YES];
            [self toggleLiveSearch:switcher];
            break;
        }
        case ZBAdvanced: {
            ZBAdvancedOrder row = indexPath.row;
            switch (row) {
                case ZBDropTables:
                    [self nukeDatabase];
                    break;
                case ZBOpenDocs:
                    [self openDocumentsDirectory];
                    break;
                case ZBClearImageCache:
                    [self resetImageCache];
                    break;
                case ZBClearKeychain:
                    [self clearKeychain];
                    break;
            }
            break;
        }
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case ZBFeatured:
            return NSLocalizedString(@"Display featured packages on the homepage.", @"");
        case ZBNews:
            return NSLocalizedString(@"Display recent community posts from /r/jailbreak.", @"");
        case ZBSearch:
            return NSLocalizedString(@"Search packages while typing. Disabling this feature may reduce lag on older devices.", @"");
        case ZBMisc:
            return NSLocalizedString(@"Configure the appearance of table view swipe actions.", @"");
        default:
            return NULL;
    }
}

# pragma mark selected cells methods

- (void)showRefreshView:(NSNumber *)dropTables {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(showRefreshView:) withObject:dropTables waitUntilDone:NO];
    } else {
        ZBRefreshViewController *refreshController = [[ZBRefreshViewController alloc] initWithDropTables:[dropTables boolValue]];
        [self presentViewController:refreshController animated:YES completion:nil];
    }
}

- (void)nukeDatabase {
    [self showRefreshView:@(YES)];
}

- (void)openDocumentsDirectory {
    NSString *documents = [ZBAppDelegate documentsDirectory];
    NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"filza://view%@/", documents] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)resetImageCache {
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
    [ZBAppDelegate sendAlertFrom:self message:NSLocalizedString(@"Resetting image cache completed", @"")];
}

- (void)clearKeychain {
    NSArray *secItemClasses = @[(__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecClassInternetPassword,
                                (__bridge id)kSecClassCertificate,
                                (__bridge id)kSecClassKey,
                                (__bridge id)kSecClassIdentity];
    for (id secItemClass in secItemClasses) {
        NSDictionary *spec = @{(__bridge id)kSecClass: secItemClass};
        SecItemDelete((__bridge CFDictionaryRef)spec);
    }
    [ZBAppDelegate sendAlertFrom:self message:NSLocalizedString(@"Clearing keychain completed", @"")];
}

- (void)displaySettings {
    ZBSettingsDisplayTableViewController *displayController = [[ZBSettingsDisplayTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    [[self navigationController] pushViewController:displayController animated:true];
}

- (void)changeTint {
//    NSString *theme = ZBDevice.darkModeEnabled ? @"White" : @"Black";
//    ZBSettingsOptionsTableViewController * controller = [[ZBSettingsOptionsTableViewController alloc] initWithStyle: UITableViewStyleGrouped];
//    controller.settingTitle = @"Accent Color";
//    controller.settingFooter = @[@"Change the accent color that displays across Zebra."];
//    controller.settingOptions = @[@"Default", @"Blue", @"Orange", theme];
//    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:tintSelectionKey];
//    controller.settingSelectedRow = number ? (ZBTintSelection)[number integerValue] : ZBDefaultTint;
//    controller.settingChanged = ^(NSInteger newValue) {
//        self->tintColorType = (ZBTintSelection) newValue;
//        [[NSUserDefaults standardUserDefaults] setObject:@(newValue) forKey:tintSelectionKey];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//        [ZBDevice hapticButton];
//        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//            [self.tableView reloadData];
//            [ZBDevice darkModeEnabled] ? [ZBDevice configureDarkMode] : [ZBDevice configureLightMode];
//            [ZBDevice refreshViews];
//            [self setNeedsStatusBarAppearanceUpdate];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"darkMode" object:nil];
//        } completion:nil];
//    };
//    [self.navigationController pushViewController: controller animated:YES];
}

- (void)changeMode {
//    ZBSettingsOptionsTableViewController * controller = [[ZBSettingsOptionsTableViewController alloc] initWithStyle: UITableViewStyleGrouped];
//    controller.settingTitle = @"Dark Mode Style";
//    controller.settingFooter = @[@"Change the style of Zebra's dark mode when it is enabled."];
//    
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:thirteenModeKey]) {
//        controller.settingSelectedRow = ZBThirteen;
//    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:oledModeKey]) {
//        controller.settingSelectedRow = ZBOled;
//    } else {
//        controller.settingSelectedRow = ZBDefaultMode;
//    }
//    controller.settingOptions = @[@"Default", @"OLED", @"iOS 13"];
//    controller.settingChanged = ^(NSInteger newValue) {
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        self->selectedMode = (ZBModeSelection)newValue;
//        [defaults setBool:self->selectedMode == ZBThirteen forKey:thirteenModeKey];
//        [defaults setBool:self->selectedMode == ZBOled forKey:oledModeKey];
//        [defaults synchronize];
//        [ZBDevice hapticButton];
//        [self oledAnimation];
//    };
//    [self.navigationController pushViewController: controller animated:YES];
}

- (void)featureOrRandomToggle {
    ZBSettingsOptionsTableViewController * controller = [[ZBSettingsOptionsTableViewController alloc] initWithStyle: UITableViewStyleGrouped];
    controller.title = @"Feature Type";
    controller.footerText = @[@"Change the source of the featured packages on the homepage.", @"\"Repo Featured\" will display random packages from repos that support the Featured Package API.", @"\"Random\" will display random packages from all repositories that you have added to Zebra."];
    if ([[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:randomFeaturedKey]] integerValue] == 1) {
        controller.selectedRow = 1;
    } else {
        controller.selectedRow = 0;
    }
    
    controller.options = @[@"Repo Featured", @"Random"];
    controller.settingChanged = ^(NSInteger newValue) {
        BOOL selectedMode = [[NSNumber numberWithInteger:newValue] boolValue];
        [[NSUserDefaults standardUserDefaults] setBool:selectedMode forKey:randomFeaturedKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [ZBDevice hapticButton];
        [self.tableView reloadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshCollection" object:self];
        CATransition *transition = [CATransition animation];
        transition.type = kCATransitionFade;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.fillMode = kCAFillModeForwards;
        transition.duration = 0.35;
        transition.subtype = kCATransitionFromTop;
        [self.tableView.layer addAnimation:transition forKey:@"UITableViewReloadDataAnimationKey"];
    };
    [self.navigationController pushViewController: controller animated:YES];
}

- (void)changeIcon {
    if (@available(iOS 10.3, *)) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ZBAlternateIconController *altIcon = [storyboard instantiateViewControllerWithIdentifier:@"alternateIconController"];
        [self.navigationController.navigationBar setBackgroundColor:[UIColor tableViewBackgroundColor]];
        [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
        [self.navigationController pushViewController:altIcon animated:YES];
    }
}

- (void)toggle:(id)sender preference:(NSString *)preferenceKey notification:(NSString *)notificationKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UISwitch *switcher = (UISwitch *)sender;
    BOOL value = [defaults boolForKey:preferenceKey];
    value = switcher.isOn;
    [defaults setBool:value forKey:preferenceKey];
    [defaults synchronize];
    [ZBDevice hapticButton];
    if (notificationKey) {
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationKey object:self];
    }
    
    if ([preferenceKey isEqualToString:wantsFeaturedKey]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ZBFeatured] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        });
    }
}

- (void)toggleFeatured:(id)sender {
    [self toggle:sender preference:wantsFeaturedKey notification:@"toggleFeatured"];
}

- (void)toggleNews:(id)sender {
    [self toggle:sender preference:wantsNewsKey notification:@"toggleNews"];
}

- (void)toggleLiveSearch:(id)sender {
    [self toggle:sender preference:liveSearchKey notification:nil];
}

- (void)openBlackList {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBRepoBlacklistTableViewController *blackList = [storyboard instantiateViewControllerWithIdentifier:@"repoBlacklistController"];
    [self.navigationController.navigationBar setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
    [self.navigationController pushViewController:blackList animated:YES];
}

- (void)getTappedSwitch:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UISwitch *switcher = (UISwitch *)cell.accessoryView;
    [switcher setOn:!switcher.on animated:YES];
    if (indexPath.section == ZBFeatured) {
        [self toggleFeatured:switcher];
    }
}

- (void)oledAnimation {
    [self.tableView reloadData];
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
//    [ZBDevice darkModeEnabled] ? [ZBDevice configureDarkMode] : [ZBDevice configureLightMode];
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

- (void)misc {
    ZBSettingsOptionsTableViewController * controller = [[ZBSettingsOptionsTableViewController alloc] initWithStyle: UITableViewStyleGrouped];
    if ([[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:iconActionKey]] integerValue] == 1) {
        controller.selectedRow = 1;
    } else {
        controller.selectedRow = 0;
    }
    controller.title = @"Swipe Actions Display As";
    controller.options = @[@"Text", @"Icon"];
    controller.settingChanged = ^(NSInteger newValue) {
        BOOL useIcon = newValue == 1;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:useIcon forKey:iconActionKey];
        [defaults synchronize];
    };
    [self.navigationController pushViewController: controller animated:YES];
}

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
