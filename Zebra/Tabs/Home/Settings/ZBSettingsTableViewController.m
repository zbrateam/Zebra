//
//  SettingsTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSettingsTableViewController.h"

enum ZBInfoOrder {
    ZBChangelog = 0,
    ZBRepos,
    ZBBugs
};

enum ZBUIOrder {
    ZBChangeTint = 0,
    ZBOledSwitch,
    ZBChangeIcon
};

enum ZBAdvancedOrder {
    ZBDropTables = 0,
    ZBOpenDocs,
    ZBClearImageCache,
    ZBClearKeychain
};

enum ZBSectionOrder {
    ZBInfo = 0,
    ZBGraphics,
    ZBAdvanced
};

@interface ZBSettingsTableViewController (){
    NSMutableDictionary *_colors;
}

@end

@implementation ZBSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Settings";
    self.headerView.backgroundColor = [UIColor tableViewBackgroundColor];
    [self configureNavBar];
    [self configureTitleLabel];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:TRUE];
    [self.tableView reloadData];
    [self.tableView setSeparatorColor:[UIColor cellSeparatorColor]];
    [self configureNavBar];
}

- (void)configureNavBar {
    [UIView animateWithDuration:0.3 animations:^{
        [self.navigationController.navigationBar setBackgroundColor:[UIColor tableViewBackgroundColor]];
        [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
        [self.navigationController.navigationBar setShadowImage:[UIImage new]];
        [self.navigationController.navigationBar setTranslucent:FALSE];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor cellPrimaryTextColor]}];
        [self.navigationController.navigationBar layoutIfNeeded];
    } completion:nil];
    
}

- (void)configureTitleLabel {
    NSString *versionString = [NSString stringWithFormat:@"Version: %@", PACKAGE_VERSION];
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Zebra\n\t\t%@", versionString]];
    [titleString addAttributes:@{NSFontAttributeName : [UIFont fontWithName:@".SFUIDisplay-Medium" size:36], NSForegroundColorAttributeName: [UIColor cellPrimaryTextColor]} range:NSMakeRange(0,5)];
    [titleString addAttributes:@{NSFontAttributeName : [UIFont fontWithName:@".SFUIDisplay-Medium" size:26], NSForegroundColorAttributeName: [[UIColor cellPrimaryTextColor] colorWithAlphaComponent:0.75]} range:[titleString.string rangeOfString:versionString]];
    [self.titleLabel setAttributedText:titleString];
    [self.titleLabel setTextAlignment:NSTextAlignmentNatural];
    [self.titleLabel setNumberOfLines:0];
    [self.titleLabel setTranslatesAutoresizingMaskIntoConstraints:FALSE];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeButtonTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    /*if (offsetY > 190){
        self.navigationController.navigationBar.backgroundColor = [UIColor tableViewBackgroundColor];
        [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor cellPrimaryTextColor]}];
    }else{
        [self.navigationController.navigationBar setBackgroundColor:[UIColor grayColor]];
        [self.navigationController.navigationBar setBarTintColor:[UIColor grayColor]];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    }*/
    if(offsetY < 0){
        CGRect frame = self.headerView.frame;
        frame.size.height = self.tableView.tableHeaderView.frame.size.height - scrollView.contentOffset.y;
        frame.origin.y = self.tableView.tableHeaderView.frame.origin.y + scrollView.contentOffset.y;
        self.headerView.frame = frame;
    }
}

- (NSString *)sectionTitleForSection:(NSInteger)section {
    switch (section) {
        case ZBInfo:
            return @"Information";
            break;
        case ZBGraphics:
            return @"Graphics";
            break;
        case ZBAdvanced:
            return @"Advanced";
            break;
        default:
            return @"Error";
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section){
        case ZBInfo:
            if (@available(iOS 10.3, *)) {
                return 3;
            } else {
                return 2;
            }
            break;
        case ZBGraphics:
            return 3;
            break;
        case ZBAdvanced:
            return 4;
            break;
        default:
            return 0;
            break;
    }
}



- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 10, 18)];
    [view setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [label setFont:[UIFont boldSystemFontOfSize:15]];
    [label setText:[self sectionTitleForSection:section]];
    [label setTextColor:[UIColor cellPrimaryTextColor]];
    [view addSubview:label];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[label]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-5-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
    return view;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == ZBInfo){
        static NSString *cellIdentifier = @"infoCells";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        NSString *labelText;
        UIImage *cellImage = [UIImage new];
        if(indexPath.row == ZBChangelog) {
            labelText = @"Changelog";
            cellImage = [UIImage imageNamed:@"changelog"];
        }else if(indexPath.row == ZBRepos) {
            labelText = @"Community Repos";
            cellImage = [UIImage imageNamed:@"repos"];
        }else if (indexPath.row == ZBBugs) {
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
        
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        return cell;
    }else if (indexPath.section == ZBGraphics) {
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
                } else {
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
        } else if (indexPath.row == ZBChangeTint){
            /*UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:@[@"Blue", @"Orange", @"White"]];
            segment.frame = cell.contentView.bounds;
            //segment.autoresizingMask = UIViewAutoresizingFlexibleCe
            [cell.contentView addSubview:segment];*/
            cell.textLabel.text = @"Select Tint Color";
        } else if (indexPath.row == ZBOledSwitch) {
            UISwitch *darkSwitch = [[UISwitch alloc] init];
            CGSize switchSize = [darkSwitch sizeThatFits:CGSizeZero];
            darkSwitch.frame = CGRectMake(cell.contentView.bounds.size.width - switchSize.width - 5.0f, (cell.contentView.bounds.size.height - switchSize.height) / 2.0f, switchSize.width, switchSize.height);
            darkSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            darkSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"oledMode"];
            darkSwitch.tag = 123;
            [darkSwitch addTarget:self action:@selector(toggleOledDarkMode:) forControlEvents:UIControlEventValueChanged];
            if(![cell viewWithTag:123]){
                [cell.contentView addSubview:darkSwitch];
            }
            cell.textLabel.text = @"Oled Darkmode";
        }
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        return cell;
    }else if (indexPath.section == ZBAdvanced) {
        static NSString *cellIdentifier = @"advancedCells";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        /*ZBDropTables = 0,
         ZBOpenDocs,
         ZBClearImageCache,
         ZBClearKeychain*/
        NSString *text;
        if (indexPath.row == ZBDropTables) {
            text = @"Drop Tables";
        } else if (indexPath.row == ZBOpenDocs){
            text = @"Open Documents Directory";
        } else if (indexPath.row == ZBClearImageCache) {
            text = @"Clear Image Cache";
        } else if (indexPath.row == ZBClearKeychain){
            text = @"Clear Keychain";
        }
        cell.textLabel.text = text;
        [cell.textLabel setTextColor:[UIColor tintColor]];
        return cell;
    } else {
        return nil;
    }
    
        
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ZBInfo:
            switch (indexPath.row) {
                case ZBChangelog:
                    [self openWebView:ZBChangelog];
                    break;
                case ZBRepos:
                    [self openWebView:ZBRepos];
                    break;
                case ZBBugs:
                    [self openWebView:ZBBugs];
                    break;
                default:
                    break;
            }
            break;
        case ZBGraphics:
            switch (indexPath.row) {
                case ZBChangeIcon :
                    [self changeIcon];
                    break;
                case ZBOledSwitch :
                    [self getTappedSwitch:indexPath];
                    break;
                default:
                    break;
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
                default:
                    break;
                
            }
            break;
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
}


# pragma mark selected cells methods
- (void)openWebView:(NSInteger)cellNumber {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBWebViewController *webController = [storyboard instantiateViewControllerWithIdentifier:@"webController"];
    webController.navigationDelegate = webController;
    webController.navigationItem.title = @"Loading...";
    NSURL *url;
    if(cellNumber == ZBChangelog) {
        url = [NSURL URLWithString:@"https://xtm3x.github.io/repo/depictions/xyz.willy.zebra/changelog.html"];
    }else if (cellNumber == ZBRepos) {
        url = [NSURL URLWithString:@"https://xtm3x.github.io/zebra/repos.html"];
    }else {
        url = [NSURL URLWithString:@"https://xtm3x.github.io/repo/depictions/xyz.willy.zebra/bugsbugsbugs.html"];
    }
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
        [self.navigationController pushViewController:altIcon animated:TRUE];
    } else {
        return;
    }
}

- (void)getTappedSwitch:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UISwitch *switcher = (UISwitch *)[cell.contentView viewWithTag:123];
    [switcher setOn:!switcher.on animated:YES];
    [self toggleOledDarkMode:switcher];
    
}

- (void)toggleOledDarkMode:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UISwitch *switcher = (UISwitch *)sender;
    BOOL oled = [defaults boolForKey:@"oledMode"];
    oled = switcher.isOn;
    [defaults setBool:oled forKey:@"oledMode"];
    [defaults synchronize];
    [self hapticButton];
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self oledAnimation];
    } completion:nil];
    
}

- (void)oledAnimation {
    [self.tableView reloadData];
    [self configureNavBar];
    self.headerView.backgroundColor = [UIColor tableViewBackgroundColor];
    [ZBDevice configureDarkMode];
    [ZBDevice refreshViews];
    [self setNeedsStatusBarAppearanceUpdate];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"darkMode" object:self];
}

- (void)hapticButton {
    if (@available(iOS 10.0, *)) {
        UISelectionFeedbackGenerator *feedback = [[UISelectionFeedbackGenerator alloc] init];
        [feedback prepare];
        [feedback selectionChanged];
        feedback = nil;
    } else {
        return;// Fallback on earlier versions
    }
}




/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
