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
#import <Tabs/Home/Credits/ZBCreditsTableViewController.h>
#import <Tabs/Packages/Helpers/ZBPackage.h>
#import <Community Sources/ZBCommunitySourcesTableViewController.h>
#import <Changelog/ZBChangelogTableViewController.h>
#import <Theme/ZBThemeManager.h>

@import FirebaseAnalytics;

typedef enum ZBHomeOrder : NSUInteger {
    ZBInfo,
    ZBViews,
    ZBLinks,
    ZBCredits,
    ZBHomeOrderCount
} ZBHomeOrder;

typedef enum ZBInfoOrder : NSUInteger {
    ZBWelcome,
    ZBBug
} ZBInfoOrder;

typedef enum ZBViewOrder : NSUInteger {
    ZBChangeLog,
    ZBCommunity,
    ZBStores,
    ZBWishList
} ZBViewOrder;

typedef enum ZBLinksOrder : NSUInteger {
    ZBDiscord,
    ZBTwitter,
    ZBTranslate
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
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTheme) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshCollection:) name:@"refreshCollection" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleFeatured) name:@"toggleFeatured" object:nil];
    [self.navigationItem setTitle:NSLocalizedString(@"Home", @"")];
    self.defaults = [NSUserDefaults standardUserDefaults];
    [self.featuredCollection registerNib:[UINib nibWithNibName:@"ZBFeaturedCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"imageCell"];
    self.featuredCollection.delegate = self;
    self.featuredCollection.dataSource = self;
    [self.featuredCollection setShowsHorizontalScrollIndicator:NO];
    [self.featuredCollection setContentInset:UIEdgeInsetsMake(0.f, 15.f, 0.f, 15.f)];
    [self setupFeatured];
    
    if (@available(iOS 13.0, *)) {
        UIBarButtonItem *settingsButton = self.navigationItem.rightBarButtonItems[0];
        self.navigationItem.rightBarButtonItems = nil;
        self.navigationItem.rightBarButtonItem = settingsButton;
    }
    
    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self configureFooter];
    [self.darkModeButton setImage:[[ZBThemeManager sharedInstance] toggleImage]];

    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    self.headerView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    self.navigationController.navigationBar.tintColor = [UIColor accentColor];
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
    NSMutableArray <ZBSource *>*featuredRepos = [[[ZBDatabaseManager sharedInstance] sources] mutableCopy];
    NSMutableArray *saveArray = [NSMutableArray new];
    dispatch_group_t group = dispatch_group_create();
    for (ZBSource *repo in featuredRepos) {
        dispatch_group_enter(group);
        NSURL *requestURL = [NSURL URLWithString:@"sileo-featured.json" relativeToURL:[NSURL URLWithString:repo.repositoryURI]];
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
        BOOL isDir = YES;
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
    NSArray *blockedRepos = [self.defaults arrayForKey:@"blackListedRepos"];
    NSMutableArray *blacklist = [NSMutableArray new];
    for (NSString *baseURL in blockedRepos) {
        ZBSource *repo = [ZBSource repoFromBaseURL:baseURL];
        if (repo) {
            [blacklist addObject:repo];
        }
    }
    
    NSArray *packages = [[ZBDatabaseManager sharedInstance] packagesWithReachableIcon:20 excludeFrom:blacklist];
    dispatch_group_t group = dispatch_group_create();
    for (ZBPackage *package in packages) {
        dispatch_group_enter(group);
        NSMutableDictionary *dict = [NSMutableDictionary new];
        if (package.iconPath) {
            if (![[NSURL URLWithString:package.iconPath] isFileURL] && ![[ZBDatabaseManager sharedInstance] packageIsInstalled:package versionStrict:NO]) {
                [dict setObject:package.iconPath forKey:@"url"];
                [dict setObject:package.identifier forKey:@"package"];
                [dict setObject:package.name forKey:@"title"];
                [dict setObject:package.sectionImageName forKey:@"section"];
                
                [self->allFeatured addObject:dict];
            }
        }
        dispatch_group_leave(group);
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self createHeader];
    });
}

- (void)createHeader {
    if (allFeatured.count) {
        [self.tableView beginUpdates];
        self.featuredCollection.backgroundColor = [UIColor groupedTableViewBackgroundColor];
        [self.selectedFeatured removeAllObjects];
        self.cellNumber = [self cellCount];
        
        for (int i = 1; i <= self.cellNumber; ++i) {
            NSDictionary *dict = [self->allFeatured objectAtIndex:(arc4random() % allFeatured.count)];
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
    [self.footerView setBackgroundColor:[UIColor groupedTableViewBackgroundColor]];
    [self.footerLabel setTextColor:[UIColor secondaryTextColor]];
    [self.footerLabel setNumberOfLines:1];
    [self.footerLabel setFont:[UIFont systemFontOfSize:13]];
    [self.footerLabel setText:[NSString stringWithFormat:@"%@ - iOS %@ - Zebra %@", [ZBDevice deviceModelID], [[UIDevice currentDevice] systemVersion], PACKAGE_VERSION]];
    [self.udidLabel setFont:self.footerLabel.font];
    [self.udidLabel setTextColor:[UIColor secondaryTextColor]];
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
        case ZBInfo:
            return 2;
        case ZBViews:
            return 4;
        case ZBLinks:
            return 3;
        case ZBCredits:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ZBInfo: {
            switch (indexPath.row) {
                case ZBWelcome: {
                    static NSString *cellIdentifier = @"flavorTextCell";
                    
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
                    }
                    cell.textLabel.text = NSLocalizedString(@"Welcome to Zebra!", @"");
                    cell.textLabel.textColor = [UIColor primaryTextColor];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.backgroundColor = [UIColor cellBackgroundColor];
                    
                    return cell;
                }
                case ZBBug: {
                    static NSString *cellIdentifier = @"viewCell";
                    
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
                    }
                    NSString *text;
                    UIImage *image;
                    text = NSLocalizedString(@"Report a Bug", @"");
                    image = [UIImage imageNamed:@"Bugs"];
                    [cell.textLabel setText:text];
                    [cell.imageView setImage:image];
                    [self setImageSize:cell.imageView];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.textLabel.textColor = [UIColor primaryTextColor];
                    [cell.textLabel sizeToFit];
                    cell.backgroundColor = [UIColor cellBackgroundColor];
                    
                    return cell;
                }
            }
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
                    text = NSLocalizedString(@"Changelog", @"");
                    image = [UIImage imageNamed:@"Changelog"];
                    break;
                case ZBCommunity:
                    text = NSLocalizedString(@"Community Sources", @"");
                    image = [UIImage imageNamed:@"Repos"];
                    break;
                case ZBStores:
                    text = NSLocalizedString(@"Stores", @"");
                    image = [UIImage imageNamed:@"Stores"];
                    break;
                case ZBWishList:
                    text = NSLocalizedString(@"Wish List", @"");
                    image = [UIImage imageNamed:@"Wishlist"];
                    break;
                default:
                    break;
            }
            [cell.textLabel setText:text];
            [cell.imageView setImage:image];
            [self setImageSize:cell.imageView];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.textColor = [UIColor primaryTextColor];
            [cell.textLabel sizeToFit];
            cell.backgroundColor = [UIColor cellBackgroundColor];
            
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
                    text = NSLocalizedString(@"Join our Discord", @"");
                    image = [UIImage imageNamed:@"Discord"];
                    break;
                case ZBTwitter:
                    text = NSLocalizedString(@"Follow us on Twitter", @"");
                    image = [UIImage imageNamed:@"Twitter"];
                    break;
                case ZBTranslate:
                    text = NSLocalizedString(@"Help translate Zebra!", @"");
                    image = [UIImage imageNamed:@"Translations"];
                    break;
            }
            [cell.textLabel setText:text];
            [cell.imageView setImage:image];
            [self setImageSize:cell.imageView];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.textColor = [UIColor primaryTextColor];
            [cell.textLabel sizeToFit];
            cell.backgroundColor = [UIColor cellBackgroundColor];
            
            return cell;
        }
        case ZBCredits: {
            static NSString *cellIdentifier = @"creditCell";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            }
            [cell.textLabel setText:NSLocalizedString(@"Credits", @"")];
            [cell.imageView setImage:[UIImage imageNamed:@"Credits"]];
            [self setImageSize:cell.imageView];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.textColor = [UIColor primaryTextColor];
            [cell.textLabel sizeToFit];
            cell.backgroundColor = [UIColor cellBackgroundColor];
            
            return cell;
        }
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ZBWelcome:
            return NSLocalizedString(@"Info", @"");
        case ZBLinks:
            return NSLocalizedString(@"Community", @"");
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
        case ZBInfo:
            switch (indexPath.row) {
                case ZBBug:
                    [self openBug];
                    break;
            }
            break;
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
            ZBChangelogTableViewController *changeLog = [storyboard instantiateViewControllerWithIdentifier:@"changeLogController"];
            [self.navigationController pushViewController:changeLog animated:YES];
            break;
        }
        case ZBCommunity: {
            ZBCommunitySourcesTableViewController *community = [storyboard instantiateViewControllerWithIdentifier:@"communityReposController"];
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
    ZBCreditsTableViewController *creditsController = [storyboard instantiateViewControllerWithIdentifier:@"creditsController"];
    
    [[self navigationController] pushViewController:creditsController animated:YES];
}

- (void)openBug {
    //TODO: Make bug report work again
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    ZBWebViewController *webController = [storyboard instantiateViewControllerWithIdentifier:@"webController"];
//    webController.navigationDelegate = webController;
//    webController.navigationItem.title = NSLocalizedString(@"Loading...", @"");
//    NSURL *url = [NSURL URLWithString:@"https://getzbra.com/repo/depictions/xyz.willy.Zebra/bug_report.html"];
//    [self.navigationController.navigationBar setBackgroundColor:[UIColor tableViewBackgroundColor]];
//    [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
//    [webController setValue:url forKey:@"_url"];
//    [[self navigationController] pushViewController:webController animated:YES];
}

- (void)openLinkFromRow:(NSUInteger)row {
    UIApplication *application = [UIApplication sharedApplication];
    switch (row) {
        case ZBDiscord:{
            [self openURL:[NSURL URLWithString:@"https://discord.gg/6CPtHBU"]];
            break;
        }
        case ZBTwitter: {
            NSURL *twitterapp = [NSURL URLWithString:@"twitter:///user?screen_name=getzebra"];
            NSURL *tweetbot = [NSURL URLWithString:@"tweetbot:///user_profile/getzebra"];
            NSURL *twitterweb = [NSURL URLWithString:@"https://twitter.com/getzebra"];
            if ([application canOpenURL:twitterapp]) {
                [self openURL:twitterapp];
            } else if ([application canOpenURL:tweetbot]) {
                [self openURL:tweetbot];
            } else {
                [self openURL:twitterweb];
            }
            break;
        }
        case ZBTranslate: {
            [self openURL:[NSURL URLWithString:@"https://translate.getzbra.com/"]];
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

#pragma mark - Settings

- (IBAction)settingsButtonTapped:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBStoresListTableViewController *settingsController = [storyboard instantiateViewControllerWithIdentifier:@"settingsNavController"];
    [[self navigationController] presentViewController:settingsController animated:YES completion:nil];
}

#pragma mark - Dark Mode

- (IBAction)toggleTheme:(id)sender {
    [ZBDevice hapticButton];
    
    if ([ZBThemeManager useCustomTheming]) {
        [[ZBThemeManager sharedInstance] toggleTheme];
        
        [self.darkModeButton setImage:[[ZBThemeManager sharedInstance] toggleImage]];
    }
    else {
        
    }
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

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    if ([ZBDevice themingAllowed]) {
//        return [ZBDevice darkModeEnabled] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
//    }
//    else {
//        return UIStatusBarStyleDefault;
//    }
//}

#pragma mark UICollectionView

- (UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ZBFeaturedCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
    if (indexPath.row < selectedFeatured.count) {
        NSDictionary *currentBanner = [selectedFeatured objectAtIndex:indexPath.row];
        cell.imageView.sd_imageIndicator = nil;
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:currentBanner[@"url"]] placeholderImage:[UIImage imageNamed:currentBanner[@"section"]]];
        cell.packageID = currentBanner[@"package"];
        cell.titleLabel.text = currentBanner[@"title"];
    }
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"segueHomeFeaturedToDepiction"]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        NSString *packageID = sender;
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        destination.package = [databaseManager topVersionForPackageID:packageID];
        [databaseManager closeDatabase];
    }
}

@end
