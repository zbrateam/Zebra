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
#import <ZBAppDelegate.h>

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
    ZBTwitter
} ZBLinksOrder;

@interface ZBHomeTableViewController (){
    NSMutableArray *redditPosts;
    BOOL hideUDID;
}
@property (nonatomic, weak) ZBPackageDepictionViewController *previewPackageDepictionVC;
@end

@implementation ZBHomeTableViewController

@synthesize allFeatured;
@synthesize selectedFeatured;

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideUDID) name:ZBUserWillTakeScreenshotNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUDID) name:ZBUserDidTakeScreenshotNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideUDID) name:ZBUserStartedScreenCaptureNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUDID) name:ZBUserEndedScreenCaptureNotification object:nil];
    
    [self.darkModeButton setImage:[[ZBThemeManager sharedInstance] toggleImage]];

    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    self.headerView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    self.navigationController.navigationBar.tintColor = [UIColor accentColor];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupFeatured {
    allFeatured = [NSMutableArray new];
    selectedFeatured = [NSMutableArray new];
    redditPosts = [NSMutableArray new];
    [self startFeaturedPackages];
}

- (void)startFeaturedPackages {
    self.tableView.tableHeaderView.frame = CGRectMake(self.tableView.tableHeaderView.frame.origin.x, self.tableView.tableHeaderView.frame.origin.y, self.tableView.tableHeaderView.frame.size.width, CGFLOAT_MIN);
    if ([ZBSettings wantsFeaturedPackages]) {
        if ([ZBSettings featuredPackagesType] == ZBFeaturedTypeRandom) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self packagesFromDB];
            });
        } else {
            if (![[NSFileManager defaultManager] fileExistsAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"]]) {
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
    NSMutableArray <ZBSource *>*featuredSources = [[[ZBDatabaseManager sharedInstance] sources] mutableCopy];
    NSMutableDictionary *featuredItems = [NSMutableDictionary new];
    dispatch_group_t group = dispatch_group_create();
    for (ZBSource *source in featuredSources) {
        if ([source respondsToSelector:@selector(supportsFeaturedPackages)]) { //Quick check to make sure 
            dispatch_group_enter(group);
            NSURL *requestURL = [NSURL URLWithString:@"sileo-featured.json" relativeToURL:[NSURL URLWithString:source.repositoryURI]];
            NSURL *checkingURL = requestURL;
            NSURLSession *session = [NSURLSession sharedSession];
            [[session dataTaskWithURL:checkingURL
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                        if (data != nil && (long)[httpResponse statusCode] != 404) {
                            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                            if (!source.supportsFeaturedPackages) {
                                source.supportsFeaturedPackages = YES;
                            }
                            if ([json objectForKey:@"banners"]) {
                                NSArray *banners = [json objectForKey:@"banners"];
                                if (banners.count) {
                                    [featuredItems setObject:banners forKey:[source baseFilename]];
                                }
                            }
                        }
                        dispatch_group_leave(group);
                    }] resume];
        }
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [featuredItems writeToFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"] atomically:YES];
        [self setupHeaderFromCache];
    });
}

- (void)setupHeaderFromCache {
    [allFeatured removeAllObjects];
    
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"]];
    for (NSArray *arr in [dict allValues]) {
        [allFeatured addObjectsFromArray:arr];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self createHeader];
    });
}

- (void)packagesFromDB {
    NSArray *blockedRepos = [ZBSettings sourceBlacklist];
    NSMutableArray *blacklist = [NSMutableArray new];
    for (NSString *baseFilename in blockedRepos) {
        ZBSource *source = [ZBSource sourceFromBaseFilename:baseFilename];
        if (source) {
            [blacklist addObject:source];
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
                [dict setObject:package.section forKey:@"section"];
                
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ZBHomeOrderCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case ZBInfo:
            return 2;
        case ZBViews:
            if (@available(iOS 11.0, *)) {
                return 4;
            }
            else {
                return 3;
            }
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
                    if (@available(iOS 11.0, *)) {
                        text = NSLocalizedString(@"Stores", @"");
                        image = [UIImage imageNamed:@"Stores"];
                        break;
                    }
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == ZBCredits) {
        return [NSString stringWithFormat:@"\n%@ - iOS %@ - Zebra %@%@", [ZBDevice deviceModelID], [[UIDevice currentDevice] systemVersion], PACKAGE_VERSION, hideUDID ? @"" : [@"\n" stringByAppendingString:[ZBDevice UDID]]];
    }
    return NULL;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    footer.textLabel.textAlignment = NSTextAlignmentCenter;
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
            if (@available(iOS 11.0, *)) {
                ZBStoresListTableViewController *webController = [storyboard instantiateViewControllerWithIdentifier:@"storesController"];
                [[self navigationController] pushViewController:webController animated:YES];
                break;
            }
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
    NSURL *url = [NSURL URLWithString:@"https://getzbra.com/repo/depictions/xyz.willy.Zebra/bug_report.html"];

    [ZBDevice openURL:url delegate:self];
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
    
    settingsController.presentationController.delegate = self;
}

#pragma mark - Dark Mode

- (IBAction)toggleTheme:(id)sender {
    [ZBDevice hapticButton];
    
    if ([ZBThemeManager useCustomTheming]) {
        [[ZBThemeManager sharedInstance] toggleTheme];
        
        [self.darkModeButton setImage:[[ZBThemeManager sharedInstance] toggleImage]];
    }
}

- (void)refreshCollection:(NSNotification *)notif {
    BOOL selected = [ZBSettings featuredPackagesType] == ZBFeaturedTypeRandom;
    [allFeatured removeAllObjects];
    if (selected) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self packagesFromDB];
        });
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (![[NSFileManager defaultManager] fileExistsAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"]]) {
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
    if ([ZBSettings wantsFeaturedPackages]) {
        [self refreshCollection:nil];
    } else {
        [self.tableView beginUpdates];
        self.tableView.tableHeaderView.frame = CGRectMake(self.tableView.tableHeaderView.frame.origin.x, self.tableView.tableHeaderView.frame.origin.y, self.tableView.tableHeaderView.frame.size.width, CGFLOAT_MIN);
        [self.tableView endUpdates];
    }
}

- (void)presentationControllerWillDismiss:(UIPresentationController *)presentationController {
    self.navigationController.navigationBar.tintColor = [UIColor accentColor];
}

- (void)hideUDID {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->hideUDID = YES;
        [self.tableView reloadData]; // reloadSections is too slow to use here apparently
    });
}

- (void)showUDID {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->hideUDID = NO;
        [self.tableView reloadData]; // reloadSections is too slow to use here apparently
    });
}

#pragma mark UICollectionView

- (UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ZBFeaturedCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
    if (indexPath.row < selectedFeatured.count) {
        NSDictionary *currentBanner = [selectedFeatured objectAtIndex:indexPath.row];
        NSString *section = currentBanner[@"section"];
        if (section == NULL) section = @"Unknown";
        
        cell.imageView.sd_imageIndicator = nil;
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:currentBanner[@"url"]] placeholderImage:[UIImage imageNamed:section]];
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

- (void)setPackageOnDestinationVC:(ZBPackageDepictionViewController *)destination withPackage:(NSString *)packageID {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    destination.package = [databaseManager topVersionForPackageID:packageID];
    [databaseManager closeDatabase];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"segueHomeFeaturedToDepiction"]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        [self setPackageOnDestinationVC:destination withPackage:sender];
    }
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)){
    typeof(self) __weak weakSelf = self;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
        return weakSelf.previewPackageDepictionVC;
    } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        weakSelf.previewPackageDepictionVC = (ZBPackageDepictionViewController*)[weakSelf.storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
        
        ZBFeaturedCollectionViewCell *cell = (ZBFeaturedCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        [weakSelf setPackageOnDestinationVC:weakSelf.previewPackageDepictionVC withPackage:cell.packageID];
        weakSelf.previewPackageDepictionVC.parent = weakSelf;
        
        return [UIMenu menuWithTitle:@"" children:[weakSelf.previewPackageDepictionVC contextMenuActionItemsInTableView:nil]];
    }];
}

- (void)collectionView:(UICollectionView *)collectionView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    typeof(self) __weak weakSelf = self;
    [animator addCompletion:^{
        [weakSelf.navigationController pushViewController:weakSelf.previewPackageDepictionVC animated:YES];
    }];
}

@end
