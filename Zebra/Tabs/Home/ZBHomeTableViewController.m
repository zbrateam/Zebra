//
//  ZBHomeTableViewController.m
//  Zebra
//
//  Created by midnightchips on 7/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <ZBSettings.h>
#import "ZBHomeTableViewController.h"
#import "ZBNewsCollectionViewCell.h"

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
    ZBWishList
} ZBViewOrder;

typedef enum ZBLinksOrder : NSUInteger {
    ZBDiscord,
    ZBWilsonTwitter
} ZBLinksOrder;

@interface ZBHomeTableViewController (){
    NSMutableArray *redditPosts;
}

@end

@implementation ZBHomeTableViewController

@synthesize allFeatured;
@synthesize selectedFeatured;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetTable) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshCollection:) name:@"refreshCollection" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleFeatured) name:@"toggleFeatured" object:nil];
    [self.navigationItem setTitle:@"Home"];
    self.defaults = [NSUserDefaults standardUserDefaults];
    [self.featuredCollection registerNib:[UINib nibWithNibName:@"ZBFeaturedCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"imageCell"];
    self.featuredCollection.delegate = self;
    self.featuredCollection.dataSource = self;
    [self.featuredCollection setShowsHorizontalScrollIndicator:NO];
    [self.featuredCollection setContentInset:UIEdgeInsetsMake(0.f, 15.f, 0.f, 15.f)];
    [self setupFeatured];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([ZBDevice darkModeEnabled]) {
        [self.darkModeButton setImage:[UIImage imageNamed:@"Dark"]];
    } else {
        [self.darkModeButton setImage:[UIImage imageNamed:@"Light"]];
    }
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    [self colorWindow];
}

- (void)setupFeatured {
    allFeatured = [NSMutableArray new];
    selectedFeatured = [NSMutableArray new];
    redditPosts = [NSMutableArray new];
    [self configureFooter];
    [self startFeaturedPackages];
}

- (void)startFeaturedPackages {
    self.tableView.tableHeaderView.frame = CGRectMake(self.tableView.tableHeaderView.frame.origin.x, self.tableView.tableHeaderView.frame.origin.y, self.tableView.tableHeaderView.frame.size.width, CGFLOAT_MIN);
    if ([self.defaults boolForKey:wantsFeaturedKey]) {
        if ([self.defaults boolForKey:randomFeaturedKey]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self packagesFromDB];
            });
        } else {
            if (![[NSFileManager defaultManager] fileExistsAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"Cache/Featured.plist"]]) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self cacheJSON];
                });
            } else {
                [self setupHeaderFromCache];
            }
        }
    }
}

- (void)cacheJSON {
    NSMutableArray <ZBRepo *>*featuredRepos = [[[ZBDatabaseManager sharedInstance] repos] mutableCopy];
    NSMutableArray *saveArray = [NSMutableArray new];
    dispatch_group_t group = dispatch_group_create();
    for (ZBRepo *repo in featuredRepos) {
        NSString *basePlusHttp;
        if (repo.isSecure) {
            basePlusHttp = [NSString stringWithFormat:@"https://%@", repo.baseURL];
        } else {
            basePlusHttp = [NSString stringWithFormat:@"http://%@", repo.baseURL];
        }
        dispatch_group_enter(group);
        NSURL *requestURL = [NSURL URLWithString:@"sileo-featured.json" relativeToURL:[NSURL URLWithString:basePlusHttp]];
        NSLog(@"[Zebra] Cached JSON request URL: %@", requestURL.absoluteString);
        NSURL *checkingURL = requestURL;
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithURL:checkingURL
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                    if (data != nil && (long)[httpResponse statusCode] != 404) {
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                        NSLog(@"[Zebra] JSON response data: %@", json);
                        if (!repo.supportsFeaturedPackages) {
                            repo.supportsFeaturedPackages = YES;
                        }
                        if ([json objectForKey:@"banners"]) {
                            NSArray *banners = [json objectForKey:@"banners"];
                            if (banners.count) {
                                [saveArray addObjectsFromArray:banners];
                            }
                        }
                    }
                    dispatch_group_leave(group);
                }] resume];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = TRUE;
        if (![fileManager fileExistsAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"Cache"] isDirectory:&isDir]) {
            [fileManager createDirectoryAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"Cache"] withIntermediateDirectories:NO attributes:nil error:nil];
        }
        [saveArray writeToFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"Cache/Featured.plist"] atomically:YES];
        [self setupHeaderFromCache];
    });
}

- (void)setupHeaderFromCache {
    [allFeatured removeAllObjects];
    [allFeatured addObjectsFromArray:[NSArray arrayWithContentsOfFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"Cache/Featured.plist"]]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self createHeader];
    });
}

- (void)packagesFromDB {
    NSArray *packages = [[ZBDatabaseManager sharedInstance] packagesWithReachableIconsForRows:500];
    NSArray *blockedRepos = [self.defaults arrayForKey:@"blackListedRepos"];
    NSLog(@"[Zebra] Blocked REPOS %@", blockedRepos);
    if (!blockedRepos) {
        blockedRepos = [NSArray new];
    }
    dispatch_group_t group = dispatch_group_create();
    for (ZBPackage *package in packages) {
        dispatch_group_enter(group);
        NSMutableDictionary *dict = [NSMutableDictionary new];
        if (![blockedRepos containsObject:package.repo.baseURL]) {
            if (package.iconPath) {
                if (![[NSURL URLWithString:package.iconPath] isFileURL] && ![[ZBDatabaseManager sharedInstance] packageIsInstalled:package versionStrict:NO]) {
                    [dict setObject:package.iconPath forKey:@"url"];
                    [dict setObject:package.identifier forKey:@"package"];
                    [dict setObject:package.name forKey:@"title"];
                    [self->allFeatured addObject:dict];
                }
            }
        }
        dispatch_group_leave(group);
    }
    if (self->allFeatured.count < 100) {
        NSArray *repos = [[ZBDatabaseManager sharedInstance] repos];
        NSMutableArray *filtered = [NSMutableArray new];
        for (ZBRepo *repo in repos) {
            if (![blockedRepos containsObject:repo.baseURL]) {
                [filtered addObject:repo];
            }
        }
        /*while (self -> allFeatured.count < 100) {
            
            NSArray *packages = [[ZBDatabaseManager sharedInstance] packagesFromRepo:NULL inSection:NULL numberOfPackages:300 startingAt:0];
        }*/
        // NSMutableArray *filtered
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self createHeader];
    });
}

- (void)createHeader {
    if (allFeatured.count) {
        [self.tableView beginUpdates];
        self.featuredCollection.backgroundColor = [UIColor tableViewBackgroundColor];
        [self.selectedFeatured removeAllObjects];
        self.cellNumber = [self cellCount];
        for (int i = 1; i <= self.cellNumber; ++i) {
            NSDictionary *dict = [self->allFeatured objectAtIndex:(arc4random() % allFeatured.count)];
            if ([[ZBDatabaseManager sharedInstance] packageIDIsInstalled:dict[@"package"] version:nil]) {
                --i;
                continue;
            }
            if (![selectedFeatured containsObject:dict]) {
                [self->selectedFeatured addObject:dict];
            } else {
                --i;
            }
        }
        [UIView animateWithDuration:.25f animations:^{
            self.tableView.tableHeaderView.frame = CGRectMake(self.tableView.tableHeaderView.frame.origin.x, self.tableView.tableHeaderView.frame.origin.y, self.tableView.tableHeaderView.frame.size.width, 180);
        }];
        [self.tableView endUpdates];
        [self.featuredCollection reloadData];
    }
}

- (NSInteger)cellCount {
    return MIN(5, allFeatured.count);
}

- (void)configureFooter {
    [self.footerView setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self.footerLabel setTextColor:[UIColor cellSecondaryTextColor]];
    [self.footerLabel setNumberOfLines:1];
    [self.footerLabel setFont:[UIFont systemFontOfSize:13]];
    [self.footerLabel setText:[NSString stringWithFormat:@"%@ - iOS %@ - Zebra %@", [ZBDevice deviceModelID], [[UIDevice currentDevice] systemVersion], PACKAGE_VERSION]];
    [self.udidLabel setFont:self.footerLabel.font];
    [self.udidLabel setTextColor:[UIColor cellSecondaryTextColor]];
    [self.udidLabel setNumberOfLines:1];
    [self.udidLabel setAdjustsFontSizeToFitWidth:YES];
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
        case ZBViews:
            return 4;
        case ZBLinks:
            return 2;
        case ZBCredits:
            return 1;
        default:
            return 0;
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
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
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
                default:
                    break;
            }
            [cell.textLabel setText:text];
            [cell.imageView setImage:image];
            [self setImageSize:cell.imageView];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            [cell.textLabel sizeToFit];
            return cell;
        }
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
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            [cell.textLabel sizeToFit];
            return cell;
            
        }
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
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            [cell.textLabel sizeToFit];
            return cell;
        }
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ZBWelcome:
            return @"Info";
        case ZBLinks:
            return @"Community";
        default:
            return nil;
    }
}

- (void)setImageSize:(UIImageView *)imageView {
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)pushToView:(NSUInteger)row {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    switch (row) {
        case ZBChangeLog: {
            ZBChangeLogTableViewController *changeLog = [storyboard instantiateViewControllerWithIdentifier:@"changeLogController"];
            [self.navigationController pushViewController:changeLog animated:YES];
            break;
        }
        case ZBCommunity: {
            ZBCommunityReposTableViewController *community = [storyboard instantiateViewControllerWithIdentifier:@"communityReposController"];
            [self.navigationController pushViewController:community animated:YES];
            break;
        }
        case ZBStores: {
            ZBStoresListTableViewController *webController = [storyboard instantiateViewControllerWithIdentifier:@"storesController"];
            [[self navigationController] pushViewController:webController animated:YES];
            break;
        }
        case ZBWishList: {
            ZBWishListTableViewController *webController = [storyboard instantiateViewControllerWithIdentifier:@"wishListController"];
            [[self navigationController] pushViewController:webController animated:YES];
            break;
        }
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
    
    [[self navigationController] pushViewController:webController animated:YES];
}

- (void)openLinkFromRow:(NSUInteger)row {
    UIApplication *application = [UIApplication sharedApplication];
    switch (row) {
        case ZBDiscord:{
            [self openURL:[NSURL URLWithString:@"https://discord.gg/6CPtHBU"]];
            break;
        }
        case ZBWilsonTwitter: {
            NSURL *twitterapp = [NSURL URLWithString:@"twitter:///user?screen_name=xtm3x"];
            NSURL *tweetbot = [NSURL URLWithString:@"tweetbot:///user_profile/xtm3x"];
            NSURL *twitterweb = [NSURL URLWithString:@"https://twitter.com/xtm3x"];
            if ([application canOpenURL:twitterapp]) {
                [self openURL:twitterapp];
            } else if ([application canOpenURL:tweetbot]) {
                [self openURL:tweetbot];
            } else {
                [self openURL:twitterweb];
            }
            break;
        }
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
    [[self navigationController] presentViewController:settingsController animated:YES completion:nil];
}

#pragma mark darkmode
- (IBAction)toggleDarkMode:(id)sender {
    [ZBDevice hapticButton];
    [self darkMode];
}

- (void)darkMode {
    [ZBDevice setDarkModeEnabled:![ZBDevice darkModeEnabled]];
    if ([ZBDevice darkModeEnabled]) {
        [ZBDevice configureDarkMode];
        [self.darkModeButton setImage:[UIImage imageNamed:@"Dark"]];
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    } else {
        [ZBDevice configureLightMode];
        [self.darkModeButton setImage:[UIImage imageNamed:@"Light"]];
        [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    }
    [ZBDevice refreshViews];
    [self colorWindow];
    [self setNeedsStatusBarAppearanceUpdate];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor cellPrimaryTextColor]}];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"darkMode" object:self];
    [self resetTable];
}

- (void)resetTable {
    [self.tableView reloadData];
    [self colorWindow];
    [self configureFooter];
    self.featuredCollection.backgroundColor = [UIColor tableViewBackgroundColor];
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

- (void)refreshCollection:(NSNotification *)notif {
    BOOL selected = [self.defaults boolForKey:randomFeaturedKey];
    [allFeatured removeAllObjects];
    if (selected) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self packagesFromDB];
        });
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (![[NSFileManager defaultManager] fileExistsAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"Cache/Featured.plist"]]) {
                    [self cacheJSON];
                } else {
                    [self setupHeaderFromCache];
                }
        });
    }
}

- (void)toggleFeatured {
    [allFeatured removeAllObjects];
    [self setupFeatured];
    if ([self.defaults boolForKey:wantsFeaturedKey]) {
        [self refreshCollection:nil];
    } else {
        [self.tableView beginUpdates];
        self.tableView.tableHeaderView.frame = CGRectMake(self.tableView.tableHeaderView.frame.origin.x, self.tableView.tableHeaderView.frame.origin.y, self.tableView.tableHeaderView.frame.size.width, CGFLOAT_MIN);
        [self.tableView endUpdates];
    }
}

- (void)animateTable {
    [self.tableView reloadData];
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionFade;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.fillMode = kCAFillModeForwards;
    transition.duration = 0.35;
    transition.subtype = kCATransitionFromTop;
    [self.tableView.layer addAnimation:transition forKey:@"UITableViewReloadDataAnimationKey"];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [ZBDevice darkModeEnabled] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (void)colorWindow {
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    [window setBackgroundColor:[UIColor tableViewBackgroundColor]];
}

#pragma mark UICollectionView
- (UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ZBFeaturedCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
    NSDictionary *currentBanner = [selectedFeatured objectAtIndex:indexPath.row];
    [cell.imageView sd_setImageWithURL:currentBanner[@"url"] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    cell.packageID = currentBanner[@"package"];
    cell.titleLabel.text = currentBanner[@"title"];
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.cellNumber;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(263, 148);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ZBFeaturedCollectionViewCell *cell = (ZBFeaturedCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"segueHomeFeaturedToDepiction" sender:cell.packageID];
}

#pragma mark Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"segueHomeFeaturedToDepiction"]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        NSString *packageID = sender;
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        destination.package = [databaseManager topVersionForPackageID:packageID];
        [databaseManager closeDatabase];
        destination.view.backgroundColor = [UIColor tableViewBackgroundColor];
    }
}

@end
