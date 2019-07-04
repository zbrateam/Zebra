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
    ZBChangeLog,
    ZBCommunity,
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
    [self.navigationItem setTitle:@"Home"];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self configureFooter];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkFeaturedPackages];
    if ([ZBDevice darkModeEnabled]) {
        [self.darkModeButton setImage:[UIImage imageNamed:@"Dark"]];
    } else {
        [self.darkModeButton setImage:[UIImage imageNamed:@"Light"]];
    }
    [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
    [self.navigationController.navigationBar setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self colorWindow];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



//Stub for now
- (void)checkFeaturedPackages {
    NSLog(@"Running");
    [self.featuredCollection removeFromSuperview];
    UIView *blankHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
    self.tableView.tableHeaderView = blankHeader;
    [self.tableView layoutIfNeeded];
    /*NSMutableArray *featuredRepos = [[self featuredRepos] mutableCopy];
    for (ZBRepo *repo in featuredRepos) {
        NSURL *requestURL = [NSURL URLWithString:@"sileo-featured.json" relativeToURL:[NSURL URLWithString:repo.baseURL]];
        NSLog(@"asdfasdf a %@", requestURL.absoluteString);
    }*/
    /*if (repo.supportsFeaturedPackages) {
        NSString *requestURL;
        if ([repo.baseURL hasSuffix:@"/"]) {
            requestURL = [NSString stringWithFormat:@"https://%@sileo-featured.json", repo.baseURL];
        }
        else {
            requestURL = [NSString stringWithFormat:@"https://%@/sileo-featured.json", repo.baseURL];
        }
        NSURL *checkingURL = [NSURL URLWithString:requestURL];
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithURL:checkingURL
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *error) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                    if (data != nil && (long)[httpResponse statusCode] != 404) {
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                        self.fullJSON = json;
                        self.featuredPackages = json[@"banners"];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self setupFeaturedPackages];
                        });
                    }
                    
                }] resume];
        
    }*/
}

- (NSArray *)featuredRepos {
    NSArray <ZBRepo *>*repos = [[ZBDatabaseManager sharedInstance] repos];
    NSMutableArray *featuredRepos = [NSMutableArray new];
    for (ZBRepo *repo in repos) {
        if (repo.supportsFeaturedPackages) {
            [featuredRepos addObject:repo];
            NSLog(@"REPO %@", repo.baseURL);
        }
    }
    return featuredRepos;
}

- (void)configureFooter {
    [self.footerView setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self.footerLabel setTextColor:[UIColor cellSecondaryTextColor]];
    [self.footerLabel setNumberOfLines:1];
    [self.footerLabel setFont:[UIFont systemFontOfSize:13]];
    [self.footerLabel setText:[NSString stringWithFormat:@"%@ - iOS %@ - Zebra %@", [ZBDevice deviceModelID], [[UIDevice currentDevice] systemVersion], PACKAGE_VERSION]];
    [self.udidLabel setFont:[UIFont systemFontOfSize:13]];
    [self.udidLabel setTextColor:[UIColor cellSecondaryTextColor]];
    [self.udidLabel setNumberOfLines:1];
    [self.udidLabel setAdjustsFontSizeToFitWidth:TRUE];
    [self.udidLabel setText:[ZBDevice UDID]];
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
            return 5;
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
                case ZBChangeLog:
                    text = @"Changelog";
                    image = [UIImage imageNamed:@"changelog"];
                    break;
                case ZBCommunity:
                    text = @"Community Repos";
                    image = [UIImage imageNamed:@"repos"];
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
            [self openCredits];
            break;
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
}

- (void)pushToView:(NSUInteger)row {
    switch (row) {
        case ZBChangeLog:{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ZBChangeLogTableViewController *changeLog = [storyboard instantiateViewControllerWithIdentifier:@"changeLogController"];
            [self.navigationController pushViewController:changeLog animated:true];
        }
            break;
        case ZBCommunity: {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ZBCommunityReposTableViewController *community = [storyboard instantiateViewControllerWithIdentifier:@"communityReposController"];
            [self.navigationController pushViewController:community animated:true];
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

- (void)openCredits {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBWebViewController *webController = [storyboard instantiateViewControllerWithIdentifier:@"webController"];
    webController.navigationDelegate = webController;
    webController.navigationItem.title = @"Loading...";
    NSURL *url = [NSURL URLWithString:@"https://xtm3x.github.io/zebra/credits.html"];
    [self.navigationController.navigationBar setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
    
    [webController setValue:url forKey:@"_url"];
    
    [[self navigationController] pushViewController:webController animated:true];
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

#pragma mark Settings

- (IBAction)settingsButtonTapped:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBStoresListTableViewController *settingsController = [storyboard instantiateViewControllerWithIdentifier:@"settingsNavController"];
    if (@available(iOS 11.0, *)) {
        settingsController.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    //[[self navigationController] pushViewController:settingsController animated:true];
    [[self navigationController] presentViewController:settingsController animated:TRUE completion:nil];
}

#pragma mark darkmode
- (IBAction)toggleDarkMode:(id)sender {
    [self hapticButton];
    [self darkMode];
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
    [ZBDevice setDarkModeEnabled:([ZBDevice darkModeEnabled]) ? FALSE : TRUE];
    [self.darkModeButton setImage:([ZBDevice darkModeEnabled]) ? [UIImage imageNamed:@"Dark"] : [UIImage imageNamed:@"Light"]];
    if ([ZBDevice darkModeEnabled]) {
        [ZBDevice configureDarkMode];
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    } else {
        [ZBDevice configureLightMode];
        [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    }
    [ZBDevice refreshViews];
    [self colorWindow];
    [self setNeedsStatusBarAppearanceUpdate];
    [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor cellPrimaryTextColor]}];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"darkMode" object:self];
    [self resetTable];
}

- (void)resetTable {
    [self.tableView reloadData];
    [self colorWindow];
    [self configureFooter];
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

- (void)colorWindow {
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    [window setBackgroundColor:[UIColor tableViewBackgroundColor]];
}

@end
