//
//  ZBRepoSectionsListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//
#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <UIColor+GlobalColors.h>
#import "ZBRepoSectionsListTableViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Sources/Helpers/ZBSource.h>
#import <Packages/Controllers/ZBPackageListTableViewController.h>
#import <Sources/Helpers/ZBSourceManager.h>
#import "UIBarButtonItem+blocks.h"
#import "ZBSourceAccountTableViewController.h"
#import "ZBFeaturedCollectionViewCell.h"

@import SDWebImage;

@interface ZBRepoSectionsListTableViewController () {
    CGSize bannerSize;
    UICKeyChainStore *keychain;
    ZBDatabaseManager *databaseManager;
    UIBarButtonItem *filterButton;
}
@property (nonatomic, strong) IBOutlet UICollectionView *featuredCollection;
@property (nonatomic, strong) NSArray *featuredPackages;
@property (nonatomic, strong) NSArray *sectionNames;
@property (nonatomic, strong) NSDictionary *sectionReadout;
@end

@implementation ZBRepoSectionsListTableViewController

@synthesize repo;
@synthesize sectionNames;
@synthesize sectionReadout;

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    databaseManager = [ZBDatabaseManager sharedInstance];
    sectionReadout = [databaseManager sectionReadoutForRepo:repo];
    sectionNames = [[sectionReadout allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    
    filterButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"") style:UIBarButtonItemStylePlain target:self action:@selector(filterButtonPressed:)];
    
    if ([repo paymentVendorURL]) {
        UIBarButtonItem *accountButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Account"] style:UIBarButtonItemStylePlain target:self action:@selector(accountButtonPressed:)];
        self.navigationItem.rightBarButtonItems = @[filterButton, accountButton];
    } else {
        self.navigationItem.rightBarButtonItem = filterButton;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationCallBack:) name:@"AuthenticationCallBack" object:nil]; // For iOS 9 and 10 Sileo Purchases
    
    UIView *container = [[UIView alloc] initWithFrame:self.navigationItem.titleView.frame];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    imageView.center = self.navigationItem.titleView.center;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.layer.cornerRadius = 5;
    imageView.layer.masksToBounds = YES;
    
    [imageView sd_setImageWithURL:[repo iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image && !error) {
                imageView.image = image;
            }
            else {
                self.navigationItem.titleView = NULL;
                self.navigationItem.title = [self->repo label];
            }
        });
    }];
    [container addSubview:imageView];
    self.navigationItem.titleView = container;
    self.title = [repo label];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    if (@available(iOS 11.0, *)) {} else {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [self.featuredCollection registerNib:[UINib nibWithNibName:@"ZBFeaturedCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"imageCell"];
    [self checkFeaturedPackages];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
}

- (void)filterButtonPressed:(id)sender {
    self.editing = !self.editing;
    filterButton.title = NSLocalizedString(self.editing ? @"Done" : @"Edit", @"");
    if (self.editing) {
        for (NSInteger i = 1; i < sectionNames.count + 1; ++i) {
            NSString *section = [sectionNames objectAtIndex:i - 1];
            if ([databaseManager isSectionEnabled:section]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
}

- (void)accountButtonPressed:(id)sender {
    [repo authenticate:^(BOOL success, NSError * _Nullable error) {
        if (!success || error) {
            if (error) {
                if (error.code != 1) [ZBAppDelegate sendAlertFrom:self message:[NSString stringWithFormat:@"Could not authenticate: %@", error.localizedDescription]];
            }
            else {
                [ZBAppDelegate sendAlertFrom:self message:@"Could not authenticate"];
            }
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                ZBSourceAccountTableViewController *accountController = [[ZBSourceAccountTableViewController alloc] initWithSource:self->repo];
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:accountController];
                
                [self presentViewController:navController animated:YES completion:nil];
            });
        }
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AuthenticationCallBack" object:nil];
}

- (void)checkFeaturedPackages {
    [self.featuredCollection removeFromSuperview];
    UIView *blankHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
    self.tableView.tableHeaderView = blankHeader;
    [self.tableView layoutIfNeeded];
    if (repo.supportsFeaturedPackages) {
        NSString *requestURL;
        if ([repo.repositoryURI hasSuffix:@"/"]) {
            requestURL = [NSString stringWithFormat:@"%@sileo-featured.json", repo.repositoryURI];
        } else {
            requestURL = [NSString stringWithFormat:@"%@/sileo-featured.json", repo.repositoryURI];
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
        self.tableView.tableHeaderView.frame = CGRectMake(self.featuredCollection.frame.origin.x, self.featuredCollection.frame.origin.y, self.featuredCollection.frame.size.width, self->bannerSize.height + 10);
    }];
    [self.tableView endUpdates];
    // [self.tableView reloadData];
}

- (void)setupRepoLogin {
    NSURLComponents *components = [NSURLComponents componentsWithURL:[[repo paymentVendorURL] URLByAppendingPathComponent:@"authenticate"] resolvingAgainstBaseURL:YES];
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
                
                [self->keychain setString:token forKey:[self->repo repositoryURI]];
                
                UICKeyChainStore *securedKeychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
                securedKeychain[[[self->repo repositoryURI] stringByAppendingString:@"payment"]] = nil;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    [securedKeychain setAccessibility:UICKeyChainStoreAccessibilityWhenPasscodeSetThisDeviceOnly
                                 authenticationPolicy:UICKeyChainStoreAuthenticationPolicyUserPresence];
                    
                    securedKeychain[[[self->repo repositoryURI] stringByAppendingString:@"payment"]] = payment;
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

- (void)authenticationCallBack:(NSNotification *)notif {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSURL *callbackURL = [notif.userInfo objectForKey:@"callBack"];
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:callbackURL resolvingAgainstBaseURL:NO];
    NSArray *queryItems = urlComponents.queryItems;
    NSMutableDictionary *queryByKeys = [NSMutableDictionary new];
    
    for (NSURLQueryItem *q in queryItems) {
        [queryByKeys setValue:[q value] forKey:[q name]];
    }
    
    NSString *token = queryByKeys[@"token"];
    NSString *payment = queryByKeys[@"payment_secret"];
    
    [keychain setString:token forKey:[repo repositoryURI]];
    
    UICKeyChainStore *securedKeychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    securedKeychain[[[repo repositoryURI] stringByAppendingString:@"payment"]] = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [securedKeychain setAccessibility:UICKeyChainStoreAccessibilityWhenPasscodeSetThisDeviceOnly
                     authenticationPolicy:UICKeyChainStoreAuthenticationPolicyUserPresence];
        
        securedKeychain[[[self->repo repositoryURI] stringByAppendingString:@"payment"]] = payment;
        
    });
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

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row != 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"repoSectionCell" forIndexPath:indexPath];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.locale = [NSLocale currentLocale];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    numberFormatter.usesGroupingSeparator = YES;
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"All Packages", @"");
        
        NSNumber *numberOfPackages = [NSNumber numberWithInt:[databaseManager numberOfPackagesInRepo:repo section:NULL]];
        cell.detailTextLabel.text = [numberFormatter stringFromNumber:numberOfPackages];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        NSString *section = [sectionNames objectAtIndex:indexPath.row - 1];
        cell.textLabel.text = NSLocalizedString(section, @"");
        
        cell.detailTextLabel.text = [numberFormatter stringFromNumber:(NSNumber *)[sectionReadout objectForKey:section]];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.editing || indexPath.row == 0) return;
    NSString *section = [sectionNames objectAtIndex:indexPath.row - 1];
    [databaseManager filterSection:section enabled:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.editing || indexPath.row == 0) return;
    NSString *section = [sectionNames objectAtIndex:indexPath.row - 1];
    [databaseManager filterSection:section enabled:NO];
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
        destination.repo = repo;
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
//        [databaseManager updateDatabaseUsingCaching:YES singleRepo:self->repo completion:^(BOOL success, NSError * _Nonnull error) {
//            NSLog(@"Updated repo %@", self->repo);
//        }];
    }];
    
    if ([repo canDelete]) {
        UIPreviewAction *delete = [UIPreviewAction actionWithTitle:NSLocalizedString(@"Delete", @"") style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteRepoTouchAction" object:self userInfo:@{@"repo": self->repo}];
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
