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

typedef NS_ENUM(NSInteger, ZBSectionOrder) {
    ZBInfo,
    ZBGraphics,
    ZBFeatured,
    ZBNews,
    ZBSearch,
    ZBMisc,
    ZBAdvanced
};

typedef NS_ENUM(NSUInteger, ZBUIOrder) {
    ZBChangeTint,
    ZBChangeMode,
    ZBChangeIcon
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

enum ZBInfoOrder {
    ZBBugs
};

enum ZBMiscOrder {
    ZBIconAction
};

@interface ZBSettingsTableViewController () {
    NSMutableDictionary *_colors;
    ZBTintSelection tintColorType;
    ZBModeSelection selectedMode;
}

@end

@implementation ZBSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Settings", @"");
    self.headerView.image = [UIImage imageNamed:@"banner"];
    self.headerView.clipsToBounds = YES;
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    [self configureNavBar];
    [self configureTitleLabel];
    [self configureSelectedTint];
    [self configureSelectedMode];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.tableView reloadData];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    [self configureNavBar];
}

- (void)configureSelectedTint {
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:tintSelectionKey];
    if (number) {
        tintColorType = (ZBTintSelection)[number integerValue];
    } else {
        tintColorType = ZBDefaultTint;
    }
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

- (void)configureNavBar {
    self.navigationController.navigationBar.backgroundColor = [UIColor tableViewBackgroundColor];
    self.navigationController.navigationBar.barTintColor = [UIColor tableViewBackgroundColor];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barStyle = [ZBDevice darkModeEnabled] ? UIBarStyleBlack : UIBarStyleDefault;
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor cellPrimaryTextColor]};
}

- (void)configureTitleLabel {
    NSString *versionString = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Version", @""), PACKAGE_VERSION];
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Zebra\n%@", versionString]];
    [titleString addAttributes:@{NSFontAttributeName : [UIFont fontWithName:@".SFUIDisplay-Medium" size:36], NSForegroundColorAttributeName: [UIColor whiteColor]} range:NSMakeRange(0,5)];
    [titleString addAttributes:@{NSFontAttributeName : [UIFont fontWithName:@".SFUIDisplay-Medium" size:26], NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.85]} range:[titleString.string rangeOfString:versionString]];
    self.titleLabel.attributedText = titleString;
    self.titleLabel.textAlignment = NSTextAlignmentNatural;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.layer.shouldRasterize = YES;
    self.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.titleLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.titleLabel.layer.shadowRadius = 10.0;
    self.titleLabel.layer.shadowOpacity = 1.0;
}

- (IBAction)closeButtonTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    if (offsetY <= 0) {
        CGRect frame = self.headerView.frame;
        frame.size.height = self.tableView.tableHeaderView.frame.size.height - scrollView.contentOffset.y;
        frame.origin.y = self.tableView.tableHeaderView.frame.origin.y + scrollView.contentOffset.y;
        self.headerView.frame = frame;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section_ {
    ZBSectionOrder section = section_;
    switch (section) {
        case ZBInfo:
            return NSLocalizedString(@"Information", @"");
        case ZBGraphics:
            return NSLocalizedString(@"Graphics", @"");
        case ZBFeatured:
            return NSLocalizedString(@"Featured", @"");
        case ZBNews:
            return NSLocalizedString(@"News", @"");
        case ZBSearch:
            return NSLocalizedString(@"Search", @"");
        case ZBMisc:
            return NSLocalizedString(@"Miscellaneous", @"");
        case ZBAdvanced:
            return NSLocalizedString(@"Advanced", @"");
        default:
            return nil;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section_ {
    ZBSectionOrder section = section_;
    switch (section) {
        case ZBInfo:
        case ZBNews:
        case ZBMisc:
        case ZBSearch:
            return 1;
        case ZBGraphics:
            if (@available(iOS 10.3, *)) {
                return 3;
            }
            return 2;
        case ZBFeatured:
            if ([[NSUserDefaults standardUserDefaults] boolForKey:randomFeaturedKey]) {
                return 3;
            }
            return 2;
        case ZBAdvanced:
            return 4;
        default:
            return 0;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.font = [UIFont boldSystemFontOfSize:15];
    header.textLabel.textColor = [UIColor cellPrimaryTextColor];
    header.tintColor = [UIColor clearColor];
    [(UIView *)[header valueForKey:@"_backgroundView"] setBackgroundColor:[UIColor tableViewBackgroundColor]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if ((indexPath.section == ZBGraphics &&
        (indexPath.row == ZBChangeTint || indexPath.row == ZBChangeMode)) ||
        (indexPath.section == ZBFeatured && indexPath.row == ZBFeatureOrRandomToggle) ||
        indexPath.section == ZBMisc){
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
        case ZBInfo: {
            NSString *labelText;
            UIImage *cellImage = [UIImage new];
            if (indexPath.row == ZBBugs) {
                labelText = NSLocalizedString(@"Report a Bug", @"");
                cellImage = [UIImage imageNamed:@"report"];
            }
            cell.textLabel.text = labelText;
            cell.imageView.image = cellImage;
            CGSize itemSize = CGSizeMake(30, 30);
            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
            [cell.imageView.image drawInRect:imageRect];
            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            cell.imageView.layer.cornerRadius = 5;
            cell.imageView.clipsToBounds = YES;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            return cell;
        }
        case ZBGraphics: {
            ZBUIOrder row = indexPath.row;
            switch (row) {
                case ZBChangeIcon: {
                    cell.textLabel.text = NSLocalizedString(@"Change Icon", @"");
                    if (@available(iOS 10.3, *)) {
                        if ([[UIApplication sharedApplication] alternateIconName]) {
                            cell.imageView.image = [UIImage imageNamed:[[UIApplication sharedApplication] alternateIconName]];
                            
                            CGSize itemSize = CGSizeMake(30, 30);
                            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
                            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                            [cell.imageView.image drawInRect:imageRect];
                            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                            cell.imageView.layer.cornerRadius = 5;
                            cell.imageView.clipsToBounds = YES;
                        } else {
                            cell.imageView.image = [UIImage imageNamed:@"AppIcon60x60"];
                            
                            CGSize itemSize = CGSizeMake(30, 30);
                            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
                            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                            [cell.imageView.image drawInRect:imageRect];
                            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                            cell.imageView.layer.cornerRadius = 5;
                            cell.imageView.clipsToBounds = YES;
                        }
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
                case ZBChangeTint: {
                    if (self->tintColorType == ZBDefaultTint) {
                        cell.detailTextLabel.text = NSLocalizedString(@"Default", @"");
                    } else if (self->tintColorType == ZBBlue) {
                        cell.detailTextLabel.text = NSLocalizedString(@"Blue", @"");
                    } else if (self->tintColorType == ZBOrange) {
                        cell.detailTextLabel.text = NSLocalizedString(@"Orange", @"");
                    } else if (self->tintColorType == ZBWhiteOrBlack) {
                        if (ZBDevice.darkModeEnabled) {
                            cell.detailTextLabel.text = NSLocalizedString(@"White", @"");
                        } else {
                            cell.detailTextLabel.text = NSLocalizedString(@"Black", @"");
                        }
                    } else {
                        cell.detailTextLabel.text = @"";
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.textLabel.text = NSLocalizedString(@"Tint Color", @"");
                    break;
                }
                case ZBChangeMode: {
                    if (self->selectedMode == ZBDefaultMode) {
                        cell.detailTextLabel.text = NSLocalizedString(@"Default", @"");
                    } else if (self->selectedMode == ZBOled) {
                        cell.detailTextLabel.text = NSLocalizedString(@"OLED", @"");
                    } else if (self->selectedMode == ZBThirteen) {
                        cell.detailTextLabel.text = NSLocalizedString(@"iOS 13", @"");
                    } else {
                        cell.detailTextLabel.text = @"";
                    }
                    cell.textLabel.text = NSLocalizedString(@"Dark Mode", @"");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
            }
            cell.detailTextLabel.textColor = [UIColor cellSecondaryTextColor];
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
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
                    cell.textLabel.text = NSLocalizedString(@"Enable Featured Packages", @"");
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
                default: {
                    cell.textLabel.text = NSLocalizedString(@"Select Repos to be Featured", @"");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
            }
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            return cell;
        }
        case ZBNews: {
            UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            enableSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:wantsNewsKey];
            [enableSwitch addTarget:self action:@selector(toggleNews:) forControlEvents:UIControlEventValueChanged];
            [enableSwitch setOnTintColor:[UIColor tintColor]];
            cell.accessoryView = enableSwitch;
            cell.textLabel.text = NSLocalizedString(@"Enable News", @"");
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            return cell;
        }
        case ZBSearch: {
            UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            enableSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:liveSearchKey];
            [enableSwitch addTarget:self action:@selector(toggleLiveSearch:) forControlEvents:UIControlEventValueChanged];
            [enableSwitch setOnTintColor:[UIColor tintColor]];
            cell.accessoryView = enableSwitch;
            cell.textLabel.text = NSLocalizedString(@"Search while Typing", @"");
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
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
                cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            }
            cell.textLabel.text = text;
            return cell;
        }
        case ZBAdvanced: {
            NSString *text = nil;
            if (indexPath.row == ZBDropTables) {
                text = @"Drop Tables"; // This should probably not be localized since DROP TABLE is a SQL thing
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
        case ZBInfo: {
            switch (indexPath.row) {
                case ZBBugs:
                    [self openWebView:ZBBugs];
                    break;
            }
            break;
        }
        case ZBGraphics: {
            switch (indexPath.row) {
                case ZBChangeTint:
                    [self changeTint];
                    break;
                case ZBChangeMode:
                    [self changeMode];
                    break;
                case ZBChangeIcon:
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


# pragma mark selected cells methods

- (void)openChangelog {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBChangeLogTableViewController *changeLog = [storyboard instantiateViewControllerWithIdentifier:@"changeLogController"];
    [self.navigationController pushViewController:changeLog animated:YES];
}

- (void)openCommunityRepos {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBCommunityReposTableViewController *community = [storyboard instantiateViewControllerWithIdentifier:@"communityReposController"];
    [self.navigationController pushViewController:community animated:YES];
}

- (void)openWebView:(NSInteger)cellNumber {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBWebViewController *webController = [storyboard instantiateViewControllerWithIdentifier:@"webController"];
    webController.navigationDelegate = webController;
    webController.navigationItem.title = NSLocalizedString(@"Loading...", @"");
    NSURL *url = [NSURL URLWithString:@"https://xtm3x.github.io/repo/depictions/xyz.willy.zebra/bugsbugsbugs.html"];
    [self.navigationController.navigationBar setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
    [webController setValue:url forKey:@"_url"];
    [[self navigationController] pushViewController:webController animated:YES];
}

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

- (void)changeTint {
    NSString *theme = @"Black";
    if (ZBDevice.darkModeEnabled) {
        theme = @"White";
    }
    ZBSettingsOptionsTableViewController * controller = [[ZBSettingsOptionsTableViewController alloc] initWithStyle: UITableViewStyleGrouped];
    controller.title = @"Tint Color";
    controller.settingOptions = @[@"Default", @"Blue", @"Orange", theme];
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:tintSelectionKey];
    if (number) {
        controller.settingSelectedRow = (ZBTintSelection)[number integerValue];
    } else {
        controller.settingSelectedRow = ZBDefaultTint;
    }
    controller.settingChanged = ^(NSInteger newValue) {
        self->tintColorType = (ZBTintSelection) newValue;
        [[NSUserDefaults standardUserDefaults] setObject:@(newValue) forKey:tintSelectionKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [ZBDevice hapticButton];
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.tableView reloadData];
            [self configureNavBar];
            [ZBDevice darkModeEnabled] ? [ZBDevice configureDarkMode] : [ZBDevice configureLightMode];
            [ZBDevice refreshViews];
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:nil];
    };
    [self.navigationController pushViewController: controller animated:YES];
}

- (void)changeMode {
    ZBSettingsOptionsTableViewController * controller = [[ZBSettingsOptionsTableViewController alloc] initWithStyle: UITableViewStyleGrouped];
    controller.title = @"Dark Mode";
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:thirteenModeKey]) {
        controller.settingSelectedRow = ZBThirteen;
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:oledModeKey]) {
        controller.settingSelectedRow = ZBOled;
    } else {
        controller.settingSelectedRow = ZBDefaultMode;
    }
    controller.settingOptions = @[@"Default", @"OLED", @"iOS 13"];
    controller.settingChanged = ^(NSInteger newValue) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self->selectedMode = (ZBModeSelection)newValue;
        [defaults setBool:self->selectedMode == ZBThirteen forKey:thirteenModeKey];
        [defaults setBool:self->selectedMode == ZBOled forKey:oledModeKey];
        [defaults synchronize];
        [ZBDevice hapticButton];
        [self oledAnimation];
    };
    [self.navigationController pushViewController: controller animated:YES];
}

- (void)featureOrRandomToggle {
    ZBSettingsOptionsTableViewController * controller = [[ZBSettingsOptionsTableViewController alloc] initWithStyle: UITableViewStyleGrouped];
    controller.title = @"Feature Type";
    if ([[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:randomFeaturedKey]] integerValue] == 1) {
        controller.settingSelectedRow = 1;
    } else {
        controller.settingSelectedRow = 0;
    }
    controller.settingOptions = @[@"Repo Featured", @"Random"];
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
    [self configureNavBar];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    self.headerView.backgroundColor = [UIColor tableViewBackgroundColor];
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
    
    CGFloat offsetY = self.tableView.contentOffset.y;
    if (offsetY <= 0) {
        CGRect frame = self.headerView.frame;
        frame.size.height = self.tableView.tableHeaderView.frame.size.height - self.tableView.contentOffset.y;
        frame.origin.y = self.tableView.tableHeaderView.frame.origin.y + self.tableView.contentOffset.y;
        self.headerView.frame = frame;
    }
}

- (void) misc {
    ZBSettingsOptionsTableViewController * controller = [[ZBSettingsOptionsTableViewController alloc] initWithStyle: UITableViewStyleGrouped];
    controller.title = @"Swipe Actions Display As";
    if ([[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:iconActionKey]] integerValue] == 1) {
        controller.settingSelectedRow = 1;
    } else {
        controller.settingSelectedRow = 0;
    }
    controller.settingOptions = @[@"Text", @"Icon"];
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
