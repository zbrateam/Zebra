//
//  SettingsTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewController.h"
#import <Queue/ZBQueue.h>

#define oledModeKey @"oledMode"
#define tintSelectionKey @"tintSelection"
#define thirteenModeKey @"thirteenMode"
#define randomFeaturedKey @"randomFeatured"
#define wantsFeaturedKey @"wantsFeatured"
#define wantsNewsKey @"wantsNews"
#define iconActionKey @"packageIconAction"

enum ZBInfoOrder {
    ZBBugs
};

enum ZBUIOrder {
    ZBChangeTint,
    ZBChangeMode,
    ZBChangeIcon
};

enum ZBFeatureOrder {
    ZBFeaturedEnable,
    ZBFeatureOrRandomToggle,
    ZBFeatureBlacklist
};

enum ZBPackagesOrder {
    ZBIconAction
};

enum ZBAdvancedOrder {
    ZBDropTables,
    ZBOpenDocs,
    ZBClearImageCache,
    ZBClearKeychain
};

enum ZBSectionOrder {
    ZBInfo,
    ZBGraphics,
    ZBFeatured,
    ZBNews,
    ZBPackages,
    ZBAdvanced
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
    [self.tableView setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self configureNavBar];
    [self configureTitleLabel];
    [self configureSelectedTint];
    [self configureSelectedMode];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.tableView reloadData];
    [self.tableView setSeparatorColor:[UIColor cellSeparatorColor]];
    [self configureNavBar];
}

- (void)configureSelectedTint {
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:tintSelectionKey];
    if (number) {
        tintColorType = (ZBTintSelection)[number integerValue];
    }
    else {
        tintColorType = ZBDefaultTint;
    }
}

- (void)configureSelectedMode {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:thirteenModeKey]) {
        selectedMode = ZBThirteen;
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey:oledModeKey]) {
        selectedMode = ZBOled;
    }
    else {
        selectedMode = ZBDefaultMode;
    }
}

- (void)configureNavBar {
    [self.navigationController.navigationBar setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
    [self.navigationController.navigationBar setTranslucent:NO];
    //[self.navigationController.navigationBar setBarStyle:[ZBDevice darkModeEnabled] ? UIBarStyleBlack : UIBarStyleDefault];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor cellPrimaryTextColor]}];
}

- (void)configureTitleLabel {
    NSString *versionString = [NSString stringWithFormat:@"Version: %@", PACKAGE_VERSION];
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Zebra\n%@", versionString]];
    [titleString addAttributes:@{NSFontAttributeName : [UIFont fontWithName:@".SFUIDisplay-Medium" size:36], NSForegroundColorAttributeName: [UIColor whiteColor]} range:NSMakeRange(0,5)];
    [titleString addAttributes:@{NSFontAttributeName : [UIFont fontWithName:@".SFUIDisplay-Medium" size:26], NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.85]} range:[titleString.string rangeOfString:versionString]];
    [self.titleLabel setAttributedText:titleString];
    [self.titleLabel setTextAlignment:NSTextAlignmentNatural];
    [self.titleLabel setNumberOfLines:0];
    [self.titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ZBInfo:
            return @"Information";
        case ZBGraphics:
            return @"Graphics";
        case ZBFeatured:
            return @"Featured";
        case ZBNews:
            return @"News";
        case ZBPackages:
            return @"Packages";
        case ZBAdvanced:
            return @"Advanced";
        default:
            return nil;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section){
        case ZBInfo:
            return 1;
        case ZBGraphics:
            if (@available(iOS 10.3, *)) {
                return 3;
            }
            else {
                return 2;
            }
        case ZBFeatured:
            if ([[NSUserDefaults standardUserDefaults] boolForKey:randomFeaturedKey]) {
                return 3;
            }
            else {
                return 2;
            }
        case ZBNews:
            return 1;
        case ZBPackages:
            return 1;
        case ZBAdvanced:
            return 4;
        default:
            return 0;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.backgroundColor = [UIColor tableViewBackgroundColor];
    header.textLabel.font = [UIFont boldSystemFontOfSize:15];
    header.textLabel.textColor = [UIColor cellPrimaryTextColor];
    header.tintColor = [UIColor clearColor];
    [(UIView *)[header valueForKey:@"_backgroundView"] setBackgroundColor:[UIColor tableViewBackgroundColor]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ZBInfo) {
        static NSString *cellIdentifier = @"infoCells";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
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
        [cell.imageView.layer setCornerRadius:10];
        [cell.imageView setClipsToBounds:YES];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        return cell;
    }
    else if (indexPath.section == ZBGraphics) {
        static NSString *cellIdentifier = @"uiCells";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        if (indexPath.row == ZBChangeIcon) {
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
                    [cell.imageView.layer setCornerRadius:10];
                    [cell.imageView setClipsToBounds:YES];
                }
                else {
                    cell.imageView.image = [UIImage imageNamed:@"AppIcon60x60"];
                    CGSize itemSize = CGSizeMake(40, 40);
                    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
                    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                    [cell.imageView.image drawInRect:imageRect];
                    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    [cell.imageView.layer setCornerRadius:10];
                    [cell.imageView setClipsToBounds:YES];
                }
            }
        }
        else if (indexPath.row == ZBChangeTint) {
            [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            NSString *forthTint;
            if ([ZBDevice darkModeEnabled]) {
                forthTint = @"White";
            }
            else {
                forthTint = @"Black";
            }
            UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Default", @"Blue", @"Orange", forthTint]];
            segmentedControl.selectedSegmentIndex = (NSInteger)self->tintColorType;
            segmentedControl.tintColor = [UIColor tintColor];
            [segmentedControl addTarget:self action:@selector(tintColorSegmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = segmentedControl;
            cell.textLabel.text = @"Tint Color";
        }
        else if (indexPath.row == ZBChangeMode) {
            [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Default", @"OLED", @"iOS 13"]];
            segmentedControl.selectedSegmentIndex = (NSInteger)self->selectedMode;
            segmentedControl.tintColor = [UIColor tintColor];
            [segmentedControl addTarget:self action:@selector(modeValueChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = segmentedControl;
            cell.textLabel.text = @"Dark Mode";
        }
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        return cell;
    }
    else if (indexPath.section == ZBFeatured) {
        static NSString *cellIdentifier = @"uiCells";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        if (indexPath.row == ZBFeaturedEnable) {
            [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            enableSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:wantsFeaturedKey];
            [enableSwitch addTarget:self action:@selector(toggleFeatured:) forControlEvents:UIControlEventValueChanged];
            [enableSwitch setOnTintColor:[UIColor tintColor]];
            cell.accessoryView = enableSwitch;
            cell.textLabel.text = @"Enable Featured Packages";
        }
        else if (indexPath.row == ZBFeatureOrRandomToggle) {
            [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Repo Featured", @"Random"]];
            segmentedControl.selectedSegmentIndex = [[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:randomFeaturedKey]] integerValue];
            segmentedControl.tintColor = [UIColor tintColor];
            [segmentedControl addTarget:self action:@selector(featuredSegmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = segmentedControl;
            cell.textLabel.text = @"Feature Type";
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        else {
            cell.textLabel.text = @"Select Repos to be Featured";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        return cell;
    }
    else if (indexPath.section == ZBNews) {
        static NSString *cellIdentifier = @"newsCells";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        enableSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:wantsNewsKey];
        [enableSwitch addTarget:self action:@selector(toggleNews:) forControlEvents:UIControlEventValueChanged];
        [enableSwitch setOnTintColor:[UIColor tintColor]];
        cell.accessoryView = enableSwitch;
        cell.textLabel.text = @"Enable News";
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        return cell;
    }
    else if (indexPath.section == ZBPackages) {
        static NSString *cellIdentifier = @"packageCells";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        NSString *text = nil;
        if (indexPath.row == ZBIconAction) {
            text = @"Swipe Actions Display As";
            [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Text", @"Icon"]];
            segmentedControl.selectedSegmentIndex = [[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:iconActionKey]] integerValue];
            segmentedControl.tintColor = [UIColor tintColor];
            [segmentedControl addTarget:self action:@selector(iconActionSegmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = segmentedControl;
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        }
        cell.textLabel.text = text;
        return cell;
    }
    else if (indexPath.section == ZBAdvanced) {
        static NSString *cellIdentifier = @"advancedCells";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        NSString *text = nil;
        if (indexPath.row == ZBDropTables) {
            text = @"Drop Tables";
        }
        else if (indexPath.row == ZBOpenDocs){
            text = @"Open Documents Directory";
        }
        else if (indexPath.row == ZBClearImageCache) {
            text = @"Clear Image Cache";
        }
        else if (indexPath.row == ZBClearKeychain){
            text = @"Clear Keychain";
        }
        cell.textLabel.text = text;
        [cell.textLabel setTextColor:[UIColor tintColor]];
        return cell;
    }
    else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ZBInfo:
            switch (indexPath.row) {
                case ZBBugs:
                    [self openWebView:ZBBugs];
                    break;
            }
            break;
        case ZBGraphics:
            switch (indexPath.row) {
                case ZBChangeIcon :
                    [self changeIcon];
                    break;
            }
            break;
        case ZBFeatured:
            switch (indexPath.row) {
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
        case ZBNews: {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UISwitch *switcher = (UISwitch *)cell.accessoryView;
            [switcher setOn:!switcher.on animated:YES];
            [self toggleNews:switcher];
        }
            break;
        case ZBAdvanced:
            switch (indexPath.row) {
                case ZBDropTables :
                    [self nukeDatabase];
                    break;
                case ZBOpenDocs :
                    [self openDocumentsDirectory];
                    break;
                case ZBClearImageCache :
                    [self resetImageCache];
                    break;
                case ZBClearKeychain :
                    [self clearKeychain];
                    break;
            }
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


# pragma mark selected cells methods

- (void)openChangelog {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBChangeLogTableViewController *changeLog = [storyboard instantiateViewControllerWithIdentifier:@"changeLogController"];
    [self.navigationController pushViewController:changeLog animated:true];
}

- (void)openCommunityRepos {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBCommunityReposTableViewController *community = [storyboard instantiateViewControllerWithIdentifier:@"communityReposController"];
    [self.navigationController pushViewController:community animated:true];
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
    
    [[self navigationController] pushViewController:webController animated:true];
}

- (void)showRefreshView:(NSNumber *)dropTables {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(showRefreshView:) withObject:dropTables waitUntilDone:false];
    }
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ZBRefreshViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
        console.dropTables = [dropTables boolValue];
        [self presentViewController:console animated:true completion:nil];
    }
}

- (void)nukeDatabase {
    [self showRefreshView:@(YES)];
}

- (void)openDocumentsDirectory {
    NSString *documents = [ZBAppDelegate documentsDirectory];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"filza://view%@", documents]]];
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

- (void)toggleFeatured:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UISwitch *switcher = (UISwitch *)sender;
    BOOL oled = [defaults boolForKey:wantsFeaturedKey];
    oled = switcher.isOn;
    [defaults setBool:oled forKey:wantsFeaturedKey];
    [defaults synchronize];
    [ZBDevice hapticButton];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleFeatured" object:self];
}

- (void)toggleNews:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UISwitch *switcher = (UISwitch *)sender;
    BOOL oled = [defaults boolForKey:wantsNewsKey];
    oled = switcher.isOn;
    [defaults setBool:oled forKey:wantsNewsKey];
    [defaults synchronize];
    [ZBDevice hapticButton];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleNews" object:self];
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
    [self.tableView setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self configureNavBar];
    [self.tableView setSeparatorColor:[UIColor cellSeparatorColor]];
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
    if (segmentedControl.selectedSegmentIndex == 0) {
        selectedMode = ZBDefaultMode;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:NO forKey:oledModeKey];
        [defaults setBool:NO forKey:thirteenModeKey];
        [defaults synchronize];
    }
    else if (segmentedControl.selectedSegmentIndex == 1) {
        selectedMode = ZBOled;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:oledModeKey];
        [defaults setBool:NO forKey:thirteenModeKey];
        [defaults synchronize];
    }
    else if (segmentedControl.selectedSegmentIndex == 2) {
        selectedMode = ZBThirteen;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:NO forKey:oledModeKey];
        [defaults setBool:YES forKey:thirteenModeKey];
        [defaults synchronize];
    }
    
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
