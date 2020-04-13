//
//  ZBSourceSectionsListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//
#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <UIColor+GlobalColors.h>
#import "ZBSourceSectionsListTableViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Sources/Helpers/ZBSource.h>
#import <Packages/Controllers/ZBPackageListTableViewController.h>
#import <Sources/Helpers/ZBSourceManager.h>
#import "UIBarButtonItem+blocks.h"
#import "ZBSourceAccountTableViewController.h"
#import "ZBFeaturedCollectionViewCell.h"
#import "ZBSourcesAccountBanner.h"
#import <Extensions/UIImageView+Zebra.h>

@import SDWebImage;

@interface ZBSourceSectionsListTableViewController () {
    CGSize bannerSize;
    UICKeyChainStore *keychain;
    ZBDatabaseManager *databaseManager;
    BOOL editOnly;
}
@property (nonatomic, strong) IBOutlet UICollectionView *featuredCollection;
@property (nonatomic, strong) NSArray *featuredPackages;
@property (nonatomic, strong) NSArray *sectionNames;
@property (nonatomic, strong) NSMutableArray *filteredSections;
@property (nonatomic, strong) NSDictionary *sectionReadout;
@end

@implementation ZBSourceSectionsListTableViewController

@synthesize source;
@synthesize sectionNames;
@synthesize sectionReadout;
@synthesize filteredSections;

#pragma mark - Initializers

- (id)initWithSource:(ZBSource *)source {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"sourceSectionsController"];
    
    if (self) {
        self.source = source;
        editOnly = YES;
    }
    
    return self;
}

- (BOOL)showFeaturedSection {
    return !editOnly;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    databaseManager = [ZBDatabaseManager sharedInstance];
    sectionReadout = [databaseManager sectionReadoutForSource:source];
    sectionNames = [[sectionReadout allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    if (!editOnly) keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    
    filteredSections = [[[ZBSettings filteredSources] objectForKey:[source baseFilename]] mutableCopy];
    if (!filteredSections) filteredSections = [NSMutableArray new];
    
    if (!editOnly) self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIView *container = [[UIView alloc] initWithFrame:self.navigationItem.titleView.frame];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    imageView.center = self.navigationItem.titleView.center;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.layer.cornerRadius = 5;
    imageView.layer.masksToBounds = YES;
    
    [imageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image && !error) {
                imageView.image = image;
            }
            else {
                self.navigationItem.titleView = NULL;
                self.navigationItem.title = [self->source label];
            }
        });
    }];
    [container addSubview:imageView];
    self.navigationItem.titleView = container;
    self.title = [source label];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    if (!editOnly) {
        [self.featuredCollection registerNib:[UINib nibWithNibName:@"ZBFeaturedCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"imageCell"];
        [self checkFeaturedPackages];
    }
    else {
        [self.featuredCollection removeFromSuperview];
        self.tableView.tableHeaderView = nil;
        [self.tableView layoutIfNeeded];
    }
    
    if (@available(iOS 11.0, *)) {
        if (!editOnly && [source paymentVendorURL]) { // If the source supports payments/external accounts
            ZBSourcesAccountBanner *accountBanner = [[ZBSourcesAccountBanner alloc] initWithSource:source andOwner:self];
            [self.view addSubview:accountBanner];
            
            accountBanner.translatesAutoresizingMaskIntoConstraints = NO;
            [accountBanner.topAnchor constraintEqualToAnchor: self.view.layoutMarginsGuide.topAnchor].active = YES;
            [accountBanner.leadingAnchor constraintEqualToAnchor: self.view.leadingAnchor].active = YES;
            [accountBanner.widthAnchor constraintEqualToAnchor: self.view.widthAnchor].active = YES; // You can't use a trailing anchor with a UITableView apparently?
            [accountBanner.heightAnchor constraintEqualToConstant:75].active = YES;
            
            accountBanner.layer.zPosition = 100;
            self.tableView.contentInset = UIEdgeInsetsMake(75, 0, 0, 0);
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO]; // hack
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (editOnly) [self setEditing:YES animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (self.editing) {
        for (NSInteger i = 1; i < sectionNames.count + 1; ++i) {
            NSString *section = [sectionNames objectAtIndex:i - 1];
            if (![filteredSections containsObject:section]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
    }
}

- (void)accountButtonPressed:(id)sender {
    if (@available(iOS 11.0, *)) {
        [source authenticate:^(BOOL success, NSError * _Nullable error) {
            if (!success || error) {
                if (error) {
                    if (error.code != 1) [ZBAppDelegate sendAlertFrom:self message:[NSString stringWithFormat:NSLocalizedString(@"Could not authenticate: %@", @""), error.localizedDescription]];
                }
                else {
                    [ZBAppDelegate sendAlertFrom:self message:NSLocalizedString(@"Could not authenticate", @"")];
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBSourcesAccountBannerNeedsUpdate" object:nil];
                    ZBSourceAccountTableViewController *accountController = [[ZBSourceAccountTableViewController alloc] initWithSource:self->source];
                    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:accountController];
                    
                    [self presentViewController:navController animated:YES completion:nil];
                });
            }
        }];
    }
}

- (void)checkFeaturedPackages {
    [self.featuredCollection removeFromSuperview];
    self.tableView.tableHeaderView = nil;
    [self.tableView layoutIfNeeded];
    if (source.supportsFeaturedPackages) {
        NSString *requestURL;
        if ([source.repositoryURI hasSuffix:@"/"]) {
            requestURL = [NSString stringWithFormat:@"%@sileo-featured.json", source.repositoryURI];
        } else {
            requestURL = [NSString stringWithFormat:@"%@/sileo-featured.json", source.repositoryURI];
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
                        self->bannerSize = CGSizeFromString(json[@"itemSize"]);
                        self.featuredPackages = json[@"banners"];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self setupFeaturedPackages];
                        });
                    }
                    
                }] resume];
    }
}

- (void)setupFeaturedPackages {
    [self.tableView beginUpdates];
    self.tableView.tableHeaderView = self.featuredCollection;
    self.tableView.tableHeaderView.frame = CGRectZero;
    self.featuredCollection.delegate = self;
    self.featuredCollection.dataSource = self;
    [self.featuredCollection setContentInset:UIEdgeInsetsMake(0.f, 15.f, 0.f, 15.f)];
    self.featuredCollection.backgroundColor = [UIColor clearColor];
    // self.featuredCollection.collectionViewLayout.collectionViewContentSize.height = height;
    /*self.featuredCollection.frame = CGRectMake (self.featuredCollection.frame.origin.x,self.featuredCollection.frame.origin.y,self.featuredCollection.frame.size.width,height);*/ // objective c
    // [self.featuredCollection setNeedsLayout];
    // [self.featuredCollection reloadData];
    [UIView animateWithDuration:.25f animations:^{
        self.tableView.tableHeaderView.frame = CGRectMake(self.featuredCollection.frame.origin.x, self.featuredCollection.frame.origin.y, self.featuredCollection.frame.size.width, self->bannerSize.height + 30);
    }];
    [self.tableView endUpdates];
    // [self.tableView reloadData];
}

- (void)setupRepoLogin API_AVAILABLE(ios(11.0)) {
    NSURLComponents *components = [NSURLComponents componentsWithURL:[[source paymentVendorURL] URLByAppendingPathComponent:@"authenticate"] resolvingAgainstBaseURL:YES];
    if (![components.scheme isEqualToString:@"https"]) {
        return;
    }
    NSMutableArray *queryItems = [components queryItems] ? [[components queryItems] mutableCopy] : [NSMutableArray new];
    NSURLQueryItem *udid = [NSURLQueryItem queryItemWithName:@"udid" value:[ZBDevice UDID]];
    NSURLQueryItem *model = [NSURLQueryItem queryItemWithName:@"model" value:[ZBDevice deviceModelID]];
    [queryItems addObject:udid];
    [queryItems addObject:model];
    
    [components setQueryItems:queryItems];
    
    NSURL *url = [components URL];
    
    if (@available(iOS 11.0, *)) {
        static SFAuthenticationSession *session;
        session = [[SFAuthenticationSession alloc] initWithURL:url callbackURLScheme:@"sileo" completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
            if (callbackURL) {
                NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:callbackURL resolvingAgainstBaseURL:NO];
                NSArray *queryItems = urlComponents.queryItems;
                NSMutableDictionary *queryByKeys = [NSMutableDictionary new];
                for (NSURLQueryItem *q in queryItems) {
                    [queryByKeys setValue:[q value] forKey:[q name]];
                }
                NSString *token = queryByKeys[@"token"];
                NSString *payment = queryByKeys[@"payment_secret"];
                
                [self->keychain setString:token forKey:[self->source repositoryURI]];
                
                UICKeyChainStore *securedKeychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
                securedKeychain[[[self->source repositoryURI] stringByAppendingString:@"payment"]] = nil;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    [securedKeychain setAccessibility:UICKeyChainStoreAccessibilityWhenPasscodeSetThisDeviceOnly
                                 authenticationPolicy:UICKeyChainStoreAuthenticationPolicyUserPresence];
                    
                    securedKeychain[[[self->source repositoryURI] stringByAppendingString:@"payment"]] = payment;
                });
            }
            else {
                return;
            }
        }];
        
        [session start];
    } else {
        [ZBDevice openURL:url delegate:self];
    }
}

- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
    // Load finished
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    // Done button pressed
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [sectionNames count] + 1;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    return indexPath.row != 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceSectionCell" forIndexPath:indexPath];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.locale = [NSLocale currentLocale];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    numberFormatter.usesGroupingSeparator = YES;
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    cell.selectedBackgroundView.backgroundColor = [UIColor cellSelectedBackgroundColor];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"All Packages", @"");
        
        NSNumber *numberOfPackages = [NSNumber numberWithInt:[databaseManager numberOfPackagesInSource:source section:NULL]];
        cell.detailTextLabel.text = [numberFormatter stringFromNumber:numberOfPackages];
        cell.imageView.image = nil;
    } else {
        NSString *section = [sectionNames objectAtIndex:indexPath.row - 1];
        cell.textLabel.text = NSLocalizedString(section, @"");
        
        cell.detailTextLabel.text = [numberFormatter stringFromNumber:(NSNumber *)[sectionReadout objectForKey:section]];
        cell.imageView.image = [ZBSource imageForSection:section];
        [cell.imageView resize:CGSizeMake(32, 32) applyRadius:YES];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.editing || indexPath.row == 0) return;
    
    NSString *section = [sectionNames objectAtIndex:indexPath.row - 1];
    [filteredSections removeObject:section];
    [ZBSettings setSection:section filtered:NO forSource:self.source];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.editing || indexPath.row == 0) return;
    
    NSString *section = [sectionNames objectAtIndex:indexPath.row - 1];
    [filteredSections addObject:section];
    [ZBSettings setSection:section filtered:YES forSource:self.source];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    return !self.editing;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"segueFeaturedToPackageDepiction"]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        NSString *packageID = sender;
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        destination.package = [databaseManager topVersionForPackageID:packageID];
        [databaseManager closeDatabase];
        destination.view.backgroundColor = [UIColor tableViewBackgroundColor];
    } else {
        ZBPackageListTableViewController *destination = [segue destinationViewController];
        UITableViewCell *cell = (UITableViewCell *)sender;
        destination.source = source;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        if (indexPath.row != 0) {
            NSString *section = [sectionNames objectAtIndex:indexPath.row - 1];
            destination.section = [section stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            destination.title = section;
        } else {
            destination.title = NSLocalizedString(@"All Packages", @"");
        }
    }
}

// 3D Touch Actions

- (NSArray *)previewActionItems {
    UIPreviewAction *refresh = [UIPreviewAction actionWithTitle:NSLocalizedString(@"Refresh", @"") style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
//        ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
//        [databaseManager updateDatabaseUsingCaching:YES singleSource:self->source completion:^(BOOL success, NSError * _Nonnull error) {
//            NSLog(@"Updated source %@", self->source);
//        }];
    }];
    
    if ([source canDelete]) {
        UIPreviewAction *delete = [UIPreviewAction actionWithTitle:NSLocalizedString(@"Delete", @"") style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteSourceTouchAction" object:self userInfo:@{@"source": self->source}];
        }];
        
        return @[refresh, delete];
    }
    
    return @[refresh];
}

#pragma mark UICollectionView delegates
- (ZBFeaturedCollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ZBFeaturedCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
    NSDictionary *currentBanner = [self.featuredPackages objectAtIndex:indexPath.row];
    [cell.imageView sd_setImageWithURL:currentBanner[@"url"] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    cell.packageID = currentBanner[@"package"];
    [cell.titleLabel setText:currentBanner[@"title"]];
    
    // dispatch_async(dispatch_get_main_queue(), ^{
//        if ([[self.fullJSON objectForKey:@"itemCornerRadius"] doubleValue]) {
//            cell.layer.cornerRadius = [self->_fullJSON[@"itemCornerRadius"] doubleValue];
//        }
    // });
    
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_featuredPackages count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return bannerSize;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.editing = NO;
    ZBFeaturedCollectionViewCell *cell = (ZBFeaturedCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"segueFeaturedToPackageDepiction" sender:cell.packageID];
}

- (void)darkMode:(NSNotification *)notif {
    [self.tableView reloadData];
    self.tableView.sectionIndexColor = [UIColor accentColor];
    [self.navigationController.navigationBar setTintColor:[UIColor accentColor]];
}

@end
