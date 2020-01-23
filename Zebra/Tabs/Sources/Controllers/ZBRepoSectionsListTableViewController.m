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
    
    UIBarButtonItem *accountButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Account"] style:UIBarButtonItemStylePlain target:self action:@selector(accountButtonPressed:)];
    self.navigationItem.rightBarButtonItem = accountButton;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationCallBack:) name:@"AuthenticationCallBack" object:nil]; // For iOS 9 and 10 Sileo Purchases
    
    UIImage *image = [databaseManager iconForRepo:repo];
    if (image != NULL) {
        UIView *container = [[UIView alloc] initWithFrame:self.navigationItem.titleView.frame];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        imageView.center = self.navigationItem.titleView.center;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = image;
        imageView.layer.cornerRadius = 5;
        imageView.layer.masksToBounds = YES;
        [container addSubview:imageView];
        
        self.navigationItem.titleView = container;
    }
    else {
        self.title = [repo label];
    }
    
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

- (void)accountButtonPressed:(id)sender {
    if ([keychain stringForKey:[repo repositoryURI]]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ZBSourceAccountTableViewController *accountController = (ZBSourceAccountTableViewController *)[storyboard instantiateViewControllerWithIdentifier:@"purchasedController"];
        accountController.source = repo;
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:accountController];
        
        [self presentViewController:navController animated:true completion:nil];
    }
    else {
        [self setupRepoLogin];
    }
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
    keychain[[repo repositoryURI]] = token;
    // self->_keychain[[self.repoEndpoint stringByAppendingString:@"payment"]] = payment;
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
    } else {
        NSString *section = [sectionNames objectAtIndex:indexPath.row - 1];
        cell.textLabel.text = NSLocalizedString(section, @"");
        
        cell.detailTextLabel.text = [numberFormatter stringFromNumber:(NSNumber *)[sectionReadout objectForKey:section]];
    }
    return cell;
}

#pragma mark - Navigation

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
   ZBFeaturedCollectionViewCell *cell = (ZBFeaturedCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"segueFeaturedToPackageDepiction" sender:cell.packageID];
}

- (void)darkMode:(NSNotification *)notif {
    [self.tableView reloadData];
    self.tableView.sectionIndexColor = [UIColor accentColor];
    [self.navigationController.navigationBar setTintColor:[UIColor accentColor]];
}

@end
