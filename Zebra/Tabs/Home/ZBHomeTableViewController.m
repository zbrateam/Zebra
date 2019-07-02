//
//  ZBHomeTableViewController.m
//  Zebra
//
//  Created by midnightchips on 7/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBHomeTableViewController.h"

typedef enum ZBHomeOrder : NSUInteger {
    ZBWelcome,
    ZBViews,
    ZBLinks,
    ZBCredits,
    ZBHomeOrderCount
} ZBHomeOrder;

typedef enum ZBViewOrder : NSUInteger {
    ZBSettings,
    ZBStores,
    ZBWishList,
    ZBBug
} ZBViewOrder;

typedef enum ZBLinksOrder : NSUInteger {
    ZBDiscord,
    ZBWilsonTwitter
} ZBLinksOrder;


@interface ZBHomeTableViewController ()

@end

@implementation ZBHomeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetTable) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetTable) name:@"lightMode" object:nil];
    [self.navigationItem setTitle:@"Home"];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    if ([ZBDevice darkModeEnabled]) {
        [self.darkModeButton setImage:[UIImage imageNamed:@"Dark"]];
    } else {
        [self.darkModeButton setImage:[UIImage imageNamed:@"Light"]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ZBHomeOrderCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case ZBWelcome:
            return 1;
            break;
        case ZBViews:
            return 4;
            break;
        case ZBLinks:
            return 2;
            break;
        case ZBCredits:
            return 1;
            break;
        default:
            return 0;
            break;
    }
}

/*ZBWelcome,
 ZBViews,
 ZBLinks,
 ZBCredits,*/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ZBWelcome: {
            static NSString *cellIdentifier = @"flavorTextCell";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            }
            cell.textLabel.text = @"Welcome to the Zebra Beta!";
            [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            return cell;
        }
            break;
        case ZBViews: {
            static NSString *cellIdentifier = @"viewCell";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            }
            NSString *text;
            UIImage *image;
            switch (indexPath.row) {
                case ZBSettings:
                    text = @"Settings";
                    image = [UIImage imageNamed:@"icon"];
                    break;
                case ZBStores:
                    text = @"Stores";
                    image = [UIImage imageNamed:@"stores"];
                    break;
                case ZBWishList:
                    text = @"Wish List";
                    image = [UIImage imageNamed:@"stores"];
                    break;
                case ZBBug:
                    text = @"Report a Bug";
                    image = [UIImage imageNamed:@"report"];
                    break;
                default:
                    break;
            }
            [cell.textLabel setText:text];
            [cell.imageView setImage:image];
            [self setImageSize:cell.imageView];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
            [cell.textLabel sizeToFit];
            return cell;
        }
            break;
        case ZBLinks: {
            static NSString *cellIdentifier = @"linkCell";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            }
            NSString *text;
            UIImage *image;
            switch (indexPath.row) {
                case ZBDiscord:
                    text = @"Join our Discord";
                    image = [UIImage imageNamed:@"discord"];
                    break;
                case ZBWilsonTwitter:
                    text = @"Follow me on Twitter";
                    image = [UIImage imageNamed:@"twitter"];
                    break;
            }
            [cell.textLabel setText:text];
            [cell.imageView setImage:image];
            [self setImageSize:cell.imageView];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
            [cell.textLabel sizeToFit];
            return cell;
            
        }
           
            break;
        case ZBCredits: {
            static NSString *cellIdentifier = @"creditCell";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            }
            [cell.textLabel setText:@"Credits"];
            [cell.imageView setImage:[UIImage imageNamed:@"url"]];
            [self setImageSize:cell.imageView];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
            [cell.textLabel sizeToFit];
            return cell;
        }
            break;
            
        default:
            return nil;
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, tableView.frame.size.width - 10, 18)];
    [view setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [label setFont:[UIFont boldSystemFontOfSize:15]];
    [label setText:[self sectionTitleForSection:section]];
    [label setTextColor:[UIColor cellSecondaryTextColor]];
    [view addSubview:label];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[label]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-5-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
    return view;
}

- (NSString *)sectionTitleForSection:(NSInteger)section {
    switch (section) {
        case ZBWelcome:
            return @"Info";
            break;
        case ZBViews:
            return @"";
            break;
        case ZBLinks:
            return @"Community";
            break;
        case ZBCredits:
            return @"";
        default:
            return @"Error";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60;
}

- (void)setImageSize:(UIImageView *)imageView{
    CGSize itemSize = CGSizeMake(29, 29);
    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
    [imageView.image drawInRect:imageRect];
    imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [imageView.layer setCornerRadius:7];
    [imageView setClipsToBounds:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ZBViews:
            [self pushToView:indexPath.row];
            break;
        case ZBLinks:
            [self openLinkFromRow:indexPath.row];
            break;
        case ZBCredits:
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
}

- (void)pushToView:(NSUInteger)row {
    switch (row) {
        case ZBSettings:{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ZBStoresListTableViewController *settingsController = [storyboard instantiateViewControllerWithIdentifier:@"settingsViewController"];
            if (@available(iOS 11.0, *)) {
                settingsController.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
            }
            [[self navigationController] pushViewController:settingsController animated:true];
        }
            break;
        case ZBStores:{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ZBStoresListTableViewController *webController = [storyboard instantiateViewControllerWithIdentifier:@"storesController"];
            [[self navigationController] pushViewController:webController animated:true];
        }
            break;
            
        case ZBWishList: {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ZBStoresListTableViewController *webController = [storyboard instantiateViewControllerWithIdentifier:@"wishListController"];
            [[self navigationController] pushViewController:webController animated:true];
        }
            break;
        case ZBBug:{
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
            break;
            
        default:
            break;
    }
}

- (void)openLinkFromRow:(NSUInteger)row {
    UIApplication *application = [UIApplication sharedApplication];
    switch (row) {
        case ZBDiscord:{
            [self openURL:[NSURL URLWithString:@"https://discord.gg/6CPtHBU"]];
        }
            break;
        case ZBWilsonTwitter: {
            NSURL *twitterapp = [NSURL URLWithString:@"twitter:///user?screen_name=xtm3x"];
            NSURL *tweetbot = [NSURL URLWithString:@"tweetbot:///user_profile/xtm3x"];
            NSURL *twitterweb = [NSURL URLWithString:@"https://twitter.com/xtm3x"];
            if ([application canOpenURL:twitterapp]) {
                [self openURL:twitterapp];
            } else if ([application canOpenURL:tweetbot]){
                [self openURL:tweetbot];
            } else {
                [self openURL:twitterweb];
            }
        }
            break;
        default:
            break;
    }
}

- (void)openURL:(NSURL *)url {
    UIApplication *application = [UIApplication sharedApplication];
    if (@available(iOS 10.0, *)) {
        [application openURL:url options:@{} completionHandler:nil];
    } else {
        [application openURL:url];
    }
}

#pragma mark darkmode
- (IBAction)toggleDarkMode:(id)sender {
    [self hapticButton];
    if (![ZBDevice darkModeEnabled]) {
        //Want Dark mode
        [self darkMode];
    } else {
        //Want Light
        [self lightMode];
    }
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

- (void)darkMode {
    [ZBDevice setDarkModeEnabled:YES];
    [self.darkModeButton setImage:[UIImage imageNamed:@"Dark"]];
    [ZBDevice configureDarkMode];
    [ZBDevice refreshViews];
    [self setNeedsStatusBarAppearanceUpdate];
    [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"darkMode" object:self];
    [self.tableView reloadData];
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionFade;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.fillMode = kCAFillModeForwards;
    transition.duration = 0.35;
    transition.subtype = kCATransitionFromTop;
    [self.view.layer addAnimation:transition forKey:nil];
    [self.navigationController.navigationBar.layer addAnimation:transition forKey:nil];
    [self.tableView.layer addAnimation:transition forKey:@"UITableViewReloadDataAnimationKey"];
}

- (void)lightMode {
    [ZBDevice setDarkModeEnabled:NO];
    [self.darkModeButton setImage:[UIImage imageNamed:@"Light"]];
    [ZBDevice configureLightMode];
    [ZBDevice refreshViews];
    [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
    [self setNeedsStatusBarAppearanceUpdate];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"lightMode" object:self];
    [self.tableView reloadData];
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionFade;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.fillMode = kCAFillModeForwards;
    transition.duration = 0.35;
    transition.subtype = kCATransitionFromTop;
    [self.view.layer addAnimation:transition forKey:nil];
    [self.navigationController.navigationBar.layer addAnimation:transition forKey:nil];
    [self.tableView.layer addAnimation:transition forKey:@"UITableViewReloadDataAnimationKey"];
}

- (void)resetTable {
    [self.tableView reloadData];
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionFade;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.fillMode = kCAFillModeForwards;
    transition.duration = 0.35;
    transition.subtype = kCATransitionFromTop;
    [self.view.layer addAnimation:transition forKey:nil];
    [self.navigationController.navigationBar.layer addAnimation:transition forKey:nil];
    [self.tableView.layer addAnimation:transition forKey:@"UITableViewReloadDataAnimationKey"];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([ZBDevice darkModeEnabled]) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

@end
