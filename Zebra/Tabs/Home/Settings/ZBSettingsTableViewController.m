//
//  SettingsTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewController.h"
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
    self.navigationItem.title = @"Settings";
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
    // self.navigationController.navigationBar.barStyle = [ZBDevice darkModeEnabled] ? UIBarStyleBlack : UIBarStyleDefault;
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor cellPrimaryTextColor]};
}

- (void)configureTitleLabel {
    NSString *versionString = [NSString stringWithFormat:@"Version: %@", PACKAGE_VERSION];
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
            return @"Information";
        case ZBGraphics:
            return @"Graphics";
        case ZBFeatured:
            return @"Featured";
        case ZBNews:
            return @"News";
        case ZBSearch:
            return @"Search";
        case ZBMisc:
            return @"Miscellaneous";
        case ZBAdvanced:
            return @"Advanced";
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
    static NSString *cellIdentifier = @"settingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.imageView.image = nil;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    ZBSectionOrder section = indexPath.section;
    switch (section) {
        case ZBInfo: {
            NSString *labelText;
            UIImage *cellImage = [UIImage new];
            if (indexPath.row == ZBBugs) {
                labelText = @"Report a Bug";
                cellImage = [UIImage imageNamed:@"report"];
            }
            cell.textLabel.text = labelText;
            cell.imageView.image = cellImage;
            CGSize itemSize = CGSizeMake(40, 40);
            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
            [cell.imageView.image drawInRect:imageRect];
            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            cell.imageView.layer.cornerRadius = 10;
            cell.imageView.clipsToBounds = YES;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            return cell;
        }
        case ZBGraphics: {
            ZBUIOrder row = indexPath.row;
            switch (row) {
                case ZBChangeIcon: {
                    cell.textLabel.text = @"Change Icon";
                    if (@available(iOS 10.3, *)) {
                        if ([[UIApplication sharedApplication] alternateIconName]) {
                            cell.imageView.image = [UIImage imageNamed:[[UIApplication sharedApplication] alternateIconName]];
                            CGSize itemSize = CGSizeMake(40, 40);
                            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
                            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                            [cell.imageView.image drawInRect:imageRect];
                            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                            cell.imageView.layer.cornerRadius = 10;
                            cell.imageView.clipsToBounds = YES;
                        } else {
                            cell.imageView.image = [UIImage imageNamed:@"AppIcon60x60"];
                            CGSize itemSize = CGSizeMake(40, 40);
                            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
                            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                            [cell.imageView.image drawInRect:imageRect];
                            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                            cell.imageView.layer.cornerRadius = 10;
                            cell.imageView.clipsToBounds = YES;
                        }
                    }
                    break;
                }
                case ZBChangeTint: {
                    NSString *forthTint;
                    if ([ZBDevice darkModeEnabled]) {
                        forthTint = @"White";
                    } else {
                        forthTint = @"Black";
                    }
                    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Default", @"Blue", @"Orange", forthTint]];
                    segmentedControl.selectedSegmentIndex = (NSInteger)self->tintColorType;
                    segmentedControl.tintColor = [UIColor tintColor];
                    [segmentedControl addTarget:self action:@selector(tintColorSegmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = segmentedControl;
                    cell.textLabel.text = @"Tint Color";
                    break;
                }
                case ZBChangeMode: {
                    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Default", @"OLED", @"iOS 13"]];
                    segmentedControl.selectedSegmentIndex = (NSInteger)self->selectedMode;
                    segmentedControl.tintColor = [UIColor tintColor];
                    [segmentedControl addTarget:self action:@selector(modeValueChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = segmentedControl;
                    cell.textLabel.text = @"Dark Mode";
                    break;
                }
            }
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
                    cell.textLabel.text = @"Enable Featured Packages";
                    break;
                }
                case ZBFeatureOrRandomToggle: {
                    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Repo Featured", @"Random"]];
                    segmentedControl.selectedSegmentIndex = [[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:randomFeaturedKey]] integerValue];
                    segmentedControl.tintColor = [UIColor tintColor];
                    [segmentedControl addTarget:self action:@selector(featuredSegmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = segmentedControl;
                    cell.textLabel.text = @"Feature Type";
                    break;
                }
                default: {
                    cell.textLabel.text = @"Select Repos to be Featured";
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
            cell.textLabel.text = @"Enable News";
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            return cell;
        }
        case ZBSearch: {
            UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            enableSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:liveSearchKey];
            [enableSwitch addTarget:self action:@selector(toggleLiveSearch:) forControlEvents:UIControlEventValueChanged];
            [enableSwitch setOnTintColor:[UIColor tintColor]];
            cell.accessoryView = enableSwitch;
            cell.textLabel.text = @"Search as Typing";
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            return cell;
        }
        case ZBMisc: {
            NSString *text = nil;
            if (indexPath.row == ZBIconAction) {
                text = @"Swipe Actions Display As";
                UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Text", @"Icon"]];
                segmentedControl.selectedSegmentIndex = [[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:iconActionKey]] integerValue];
                segmentedControl.tintColor = [UIColor tintColor];
                [segmentedControl addTarget:self action:@selector(iconActionSegmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = segmentedControl;
                cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            }
            cell.textLabel.text = text;
            return cell;
        }
        case ZBAdvanced: {
            NSString *text = nil;
            if (indexPath.row == ZBDropTables) {
                text = @"Drop Tables";
            } else if (indexPath.row == ZBOpenDocs) {
                text = @"Open Documents Directory";
            } else if (indexPath.row == ZBClearImageCache) {
                text = @"Clear Image Cache";
            } else if (indexPath.row == ZBClearKeychain) {
                text = @"Clear Keychain";
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
    webController.navigationItem.title = @"Loading...";
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
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ZBRefreshViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
        console.messages = nil;
        console.dropTables = [dropTables boolValue];
        [self presentViewController:console animated:YES completion:nil];
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

- (void)tintColorSegmentedControlValueChanged:(UISegmentedControl *)segmentedControl {
    tintColorType = (ZBTintSelection)segmentedControl.selectedSegmentIndex;
    [[NSUserDefaults standardUserDefaults] setObject:@(tintColorType) forKey:tintSelectionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [ZBDevice hapticButton];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"darkMode" object:self];
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.tableView reloadData];
        [self configureNavBar];
        [ZBDevice darkModeEnabled] ? [ZBDevice configureDarkMode] : [ZBDevice configureLightMode];
        [ZBDevice refreshViews];
        [self setNeedsStatusBarAppearanceUpdate];
    } completion:nil];
}

- (void)featuredSegmentedControlValueChanged:(UISegmentedControl *)segmentedControl {
    BOOL selectedMode = [[NSNumber numberWithInteger:segmentedControl.selectedSegmentIndex] boolValue];
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
}

- (void)modeValueChanged:(UISegmentedControl *)segmentedControl {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    selectedMode = (ZBModeSelection)segmentedControl.selectedSegmentIndex;
    [defaults setBool:selectedMode == ZBThirteen forKey:thirteenModeKey];
    [defaults setBool:selectedMode == ZBOled forKey:oledModeKey];
    [defaults synchronize];
    
    [ZBDevice hapticButton];
    [self oledAnimation];
}

- (void)iconActionSegmentedControlValueChanged:(UISegmentedControl *)segmentedControl {
    BOOL useIcon = segmentedControl.selectedSegmentIndex == 1;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:useIcon forKey:iconActionKey];
    [defaults synchronize];
    [[ZBQueue sharedInstance] setUseIcon:useIcon];
}

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
