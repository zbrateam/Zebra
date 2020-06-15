//
//  SettingsTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewController.h"
#import "ZBSettingsSelectionTableViewController.h"
#import "UIImageView+Zebra.h"
#import "ZBRightIconTableViewCell.h"
#import "ZBSwitchSettingsTableViewCell.h"
#import "ZBButtonSettingsTableViewCell.h"
#import "ZBDisplaySettingsTableViewController.h"
#import "ZBSettingsResetTableViewController.h"
#import "ZBFilterSettingsTableViewController.h"
#import "ZBLanguageSettingsTableViewController.h"
#import "ZBSourceSelectTableViewController.h"

#import <ZBSettings.h>
#import <Queue/ZBQueue.h>
#import <Sources/Helpers/ZBSource.h>

typedef NS_ENUM(NSInteger, ZBSectionOrder) {
    ZBInterface,
    ZBFilters,
    ZBFeatured,
    ZBSources,
    ZBChanges,
    ZBPackages,
    ZBSearch,
    ZBConsole,
    ZBMisc,
    ZBReset
};

typedef NS_ENUM(NSUInteger, ZBInterfaceOrder) {
    ZBDisplay,
    ZBLanguage,
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
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    accentColor = [ZBSettings accentColor];
    interfaceStyle = [ZBSettings interfaceStyle];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRightIconTableViewCell" bundle:nil] forCellReuseIdentifier:@"settingsAppIconCell"];
    [self.tableView registerClass:[ZBSwitchSettingsTableViewCell class] forCellReuseIdentifier:@"settingsSwitchCell"];
    [self.tableView registerClass:[ZBButtonSettingsTableViewCell class] forCellReuseIdentifier:@"settingsButtonCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (IBAction)closeButtonTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section_ {
    ZBSectionOrder section = section_;
    switch (section) {
        case ZBFeatured:
            return NSLocalizedString(@"Home", @"");
        case ZBSources:
            return NSLocalizedString(@"Sources", @"");
        case ZBChanges:
            return NSLocalizedString(@"Changes", @"");
        case ZBSearch:
            return NSLocalizedString(@"Search", @"");
        case ZBMisc:
            return NSLocalizedString(@"Miscellaneous", @"");
        case ZBConsole:
            return NSLocalizedString(@"Console", @"");
        case ZBPackages:
            return NSLocalizedString(@"Packages", @"");
        default:
            return NULL;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 10;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section_ {
    ZBSectionOrder section = section_;
    switch (section) {
        case ZBFilters:
        case ZBChanges:
        case ZBMisc:
        case ZBSearch:
        case ZBSources:
        case ZBConsole:
        case ZBPackages:
            return 1;
        case ZBInterface:
            return 3;
        case ZBFeatured: {
            if ([ZBSettings wantsFeaturedPackages]) {
                if ([ZBSettings featuredPackagesType] == ZBFeaturedTypeRandom) {
                    return 3;
                }
                return 2;
            }
            
            return 1;
        }
        case ZBReset:
            return 2;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == ZBInterface && indexPath.row == ZBAppIcon) {
        ZBRightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsAppIconCell"];
        cell.backgroundColor = [UIColor cellBackgroundColor];
        
        cell.label.text = NSLocalizedString(@"App Icon", @"");
        
        NSDictionary *icon = [ZBAlternateIconController iconForName:[[UIApplication sharedApplication] alternateIconName]];
        UIImage *iconImage = [UIImage imageNamed:[icon objectForKey:@"iconName"]];
        [cell setAppIcon:iconImage border:[[icon objectForKey:@"border"] boolValue]];
        
        return cell;
    }
    else if ((indexPath.section == ZBFeatured && indexPath.row == ZBFeaturedEnable) || (indexPath.section >= ZBSources && indexPath.section <= ZBConsole)) {
        ZBSwitchSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsSwitchCell" forIndexPath:indexPath];
        
        ZBSectionOrder section = indexPath.section;
        switch (section) {
            case ZBFeatured: {
                cell.textLabel.text = NSLocalizedString(@"Featured Packages", @"");
                [cell setOn:[ZBSettings wantsFeaturedPackages]];
                [cell setTarget:self action:@selector(toggleFeatured:)];
                break;
            }
            case ZBSources: {
                cell.textLabel.text = NSLocalizedString(@"Automatic Refresh", @"");
                [cell setOn:[ZBSettings wantsAutoRefresh]];
                [cell setTarget:self action:@selector(toggleAutoRefresh:)];
                break;
            }
            case ZBChanges: {
                cell.textLabel.text = NSLocalizedString(@"Community News", @"");
                [cell setOn:[ZBSettings wantsCommunityNews]];
                [cell setTarget:self action:@selector(toggleNews:)];
                break;
            }
            case ZBPackages: {
                cell.textLabel.text = NSLocalizedString(@"Always Install Latest", @"");
                [cell setOn:[ZBSettings alwaysInstallLatest]];
                [cell setTarget:self action:@selector(toggleLatest:)];
                break;
            }
            case ZBSearch: {
                cell.textLabel.text = NSLocalizedString(@"Live Search", @"");
                [cell setOn:[ZBSettings wantsLiveSearch]];
                [cell setTarget:self action:@selector(toggleLiveSearch:)];
                break;
            }
            case ZBConsole: {
                cell.textLabel.text = NSLocalizedString(@"Finish Automatically", @"");
                [cell setOn:[ZBSettings wantsFinishAutomatically]];
                [cell setTarget:self action:@selector(toggleFinishAutomatically:)];
                break;
            }
            default:
                break;
        }
        
        [cell applyStyling];
        return cell;
    }
    else if ((indexPath.section == ZBFeatured && indexPath.row == ZBFeatureOrRandomToggle) || indexPath.section == ZBMisc) {
        static NSString *cellIdentifier = @"settingsRightDetailCell";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        }
    } else if (indexPath.section == ZBReset && indexPath.row == 1) {
        ZBButtonSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsButtonCell" forIndexPath:indexPath];

        cell.textLabel.text = NSLocalizedString(@"Open Documents Directory", @"");
        [cell applyStyling];
        return cell;
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
    cell.backgroundColor = [UIColor cellBackgroundColor];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.detailTextLabel.textColor = [UIColor secondaryTextColor];
    
    ZBSectionOrder section = indexPath.section;
    switch (section) {
        case ZBInterface: {
            ZBInterfaceOrder row = indexPath.row;
            switch (row) {
                case ZBDisplay: {
                    cell.textLabel.text = NSLocalizedString(@"Display", @"");
                    break;
                }
                case ZBLanguage: {
                    cell.textLabel.text = NSLocalizedString(@"Language", @"");
                    break;
                }
                case ZBAppIcon: {
                    cell.textLabel.text = NSLocalizedString(@"App Icon", @"");
                    NSDictionary *icon = [ZBAlternateIconController iconForName:[[UIApplication sharedApplication] alternateIconName]];
                    
                    cell.detailTextLabel.text = [icon objectForKey:@"shortName"];
                    
                    cell.imageView.image = [UIImage imageNamed:[icon objectForKey:@"iconName"]];
                    [cell.imageView resize:CGSizeMake(30, 30) applyRadius:YES];
                    
                    if ([[icon objectForKey:@"border"] boolValue]) {
                        [cell.imageView applyBorder];
                    }
                    else {
                        [cell.imageView removeBorder];
                    }
                    break;
                }
            }
            
            cell.textLabel.textColor = [UIColor primaryTextColor];
            cell.detailTextLabel.textColor = [UIColor secondaryTextColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
        }
        case ZBFilters: {
            cell.textLabel.text = NSLocalizedString(@"Filters", @"");
            cell.textLabel.textColor = [UIColor primaryTextColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
        }
        case ZBFeatured: {
            ZBFeatureOrder row = indexPath.row;
            switch (row) {
                case ZBFeatureOrRandomToggle: {
                    ZBFeaturedType type = [ZBSettings featuredPackagesType];

                    if (type == ZBFeaturedTypeSource) {
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
                default:
                    break;
            }
            cell.textLabel.textColor = [UIColor primaryTextColor];
            return cell;
        }
        case ZBMisc: {
            NSString *text = nil;
            if (indexPath.row == ZBIconAction) {
                text = NSLocalizedString(@"Swipe Actions Display As", @"");
                ZBSwipeActionStyle selected = [ZBSettings swipeActionStyle];
                if (selected == ZBSwipeActionStyleText) {
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
        case ZBReset: {
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Reset", @"");
                cell.textLabel.textColor = [UIColor primaryTextColor];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            return cell;
        }
        default:
            break;
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
                case ZBLanguage:
                    [self chooseLanguage];
                    break;
                case ZBAppIcon:
                    [self changeIcon];
                    break;
            }
            break;
        }
        case ZBFilters: {
            [self filterSettings];
            break;
        }
        case ZBFeatured: {
            ZBFeatureOrder row = indexPath.row;
            switch (row) {
                case ZBFeaturedEnable: {
                    ZBSwitchSettingsTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    [cell toggle];
                    break;
                }
                case ZBFeatureOrRandomToggle:
                    [self featureOrRandomToggle];
                    break;
                case ZBFeatureBlacklist:
                    [self sourceBlacklist];
                    break;
                default:
                    break;
            }
            break;
        }
        case ZBSources:
        case ZBChanges:
        case ZBPackages:
        case ZBSearch:
        case ZBConsole: {
            ZBSwitchSettingsTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [cell toggle];
            break;
        }
        case ZBMisc: {
            [self misc];
            break;
        }
        case ZBReset: {
            switch (indexPath.row) {
                case 0:
                    [self resetSettings];
                    break;
                case 1:
                    [self openDocumentsDirectory];
                    break;
            }
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
        case ZBSources:
            return NSLocalizedString(@"Refresh Zebra's sources when opening the app.", @"");
        case ZBChanges:
            return NSLocalizedString(@"Display recent community posts from /r/jailbreak.", @"");
        case ZBSearch:
            return NSLocalizedString(@"Search packages while typing. Disabling this feature may reduce lag on older devices.", @"");
        case ZBMisc:
            return NSLocalizedString(@"Configure the appearance of table view swipe actions.", @"");
        case ZBConsole:
            return NSLocalizedString(@"Automatically dismiss the Console when all of its tasks have been completed.", @"");
        case ZBPackages:
            return NSLocalizedString(@"Always install the most recent version of a package if it is not already installed.", @"");
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

- (void)filterSettings {
    ZBFilterSettingsTableViewController *filterController = [[ZBFilterSettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    [[self navigationController] pushViewController:filterController animated:YES];
}

- (void)displaySettings {
    ZBDisplaySettingsTableViewController *displayController = [[ZBDisplaySettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    [[self navigationController] pushViewController:displayController animated:YES];
}

- (void)chooseLanguage {
    ZBLanguageSettingsTableViewController *languageController = [[ZBLanguageSettingsTableViewController alloc] init];
    
    [[self navigationController] pushViewController:languageController animated:YES];
}

- (void)sourceBlacklist {
    NSMutableArray *sources = [NSMutableArray new];
    NSArray *baseFilenames = [ZBSettings sourceBlacklist];
    for (NSString *baseFilename in baseFilenames) {
        ZBSource *source = [ZBSource sourceFromBaseFilename:baseFilename];
        if (source) [sources addObject:source];
    }
    
    ZBSourceSelectTableViewController *selectSource = [[ZBSourceSelectTableViewController alloc] initWithSelectionType:ZBSourceSelectionTypeInverse limit:0 selectedSources:sources];
    [selectSource setSourcesSelected:^(NSArray<ZBSource *> * _Nonnull selectedSources) {
        NSMutableArray *blockedSources = [NSMutableArray new];
        for (ZBSource *source in selectedSources) {
            [blockedSources addObject:[source baseFilename]];
        }
        [ZBSettings setSourceBlacklist:blockedSources];
    }];
    
    [[self navigationController] pushViewController:selectSource animated:YES];
}

- (void)resetSettings {
    ZBSettingsResetTableViewController *advancedController = [[ZBSettingsResetTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    [[self navigationController] pushViewController:advancedController animated:YES];
}

- (void)openDocumentsDirectory {
    if ([[UIApplication sharedApplication] canOpenURL:[ZBAppDelegate documentsDirectoryURL]]) {
        [[UIApplication sharedApplication] openURL:[ZBAppDelegate documentsDirectoryURL] options:@{} completionHandler:nil];
    }
    else {
        UIAlertController *noMagicWord = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Filza Not Installed", @"") message:[NSString stringWithFormat:NSLocalizedString(@"Zebra cannot open its documents directory because Filza is not installed. Your documents directory is: %@", @""), [ZBAppDelegate documentsDirectory]] preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil];
        [noMagicWord addAction:ok];
        
        [self presentViewController:noMagicWord animated:YES completion:nil];
    }
}

- (void)featureOrRandomToggle {
    ZBSettingsSelectionTableViewController * controller = [[ZBSettingsSelectionTableViewController alloc] initWithOptions:@[@"Repo Featured", @"Random"] getter:@selector(featuredPackagesType) setter:@selector(setFeaturedPackagesType:) settingChangedCallback:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshCollection" object:self];
    }];
    
    [controller setTitle:@"Feature Type"];
    [controller setFooterText:@[@"Change the source of the featured packages on the homepage.", @"\"Repo Featured\" will display random packages from repos that support the Featured Package API.", @"\"Random\" will display random packages from all repositories that you have added to Zebra."]];
    
    [self.navigationController pushViewController: controller animated:YES];
}

- (void)changeIcon {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBAlternateIconController *altIcon = [storyboard instantiateViewControllerWithIdentifier:@"alternateIconController"];
    [self.navigationController pushViewController:altIcon animated:YES];
}

- (void)toggleFeatured:(NSNumber *)newValue {
    [ZBSettings setWantsFeaturedPackages:[newValue boolValue]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleFeatured" object:self];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ZBFeatured] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
}

- (void)toggleAutoRefresh:(NSNumber *)newValue {
    [ZBSettings setWantsAutoRefresh:[newValue boolValue]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ZBSources] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
}

- (void)toggleNews:(NSNumber *)newValue {
    [ZBSettings setWantsCommunityNews:[newValue boolValue]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleNews" object:self];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ZBChanges] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
}

- (void)toggleLatest:(NSNumber *)newValue {
    [ZBSettings setAlwaysInstallLatest:[newValue boolValue]];
}

- (void)toggleLiveSearch:(NSNumber *)newValue {
    [ZBSettings setWantsLiveSearch:[newValue boolValue]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ZBSearch] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
}

- (void)toggleFinishAutomatically:(NSNumber *)newValue {
    [ZBSettings setWantsFinishAutomatically:[newValue boolValue]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ZBConsole] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    });
}

- (void)misc {
    ZBSettingsSelectionTableViewController *controller = [[ZBSettingsSelectionTableViewController alloc] initWithOptions:@[@"Text", @"Icon"] getter:@selector(swipeActionStyle) setter:@selector(setSwipeActionStyle:) settingChangedCallback:nil];
    [controller setTitle:@"Swipe Actions Display As"];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
