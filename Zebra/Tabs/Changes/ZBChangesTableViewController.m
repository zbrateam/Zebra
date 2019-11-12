//
//  ZBChangesTableViewController.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 2/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <ZBLog.h>
#import <ZBAppDelegate.h>
#import <ZBSettings.h>
#import <ZBPackagePartitioner.h>
#import <ZBSortingType.h>
#import "ZBChangesTableViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActionsManager.h>
#import <Packages/Views/ZBPackageTableViewCell.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>

@import SDWebImage;
@import FirebaseAnalytics;

@interface ZBChangesTableViewController () {
    NSUserDefaults *defaults;
    NSArray *packages;
    NSArray *availableOptions;
    NSMutableArray *sectionIndexTitles;
    int totalNumberOfPackages;
    int numberOfPackages;
    int databaseRow;
}
@end

@implementation ZBChangesTableViewController

- (BOOL)useBatchLoad {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyLocalization];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleNews) name:@"toggleNews" object:nil];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.contentInset = UIEdgeInsetsMake(5, 0, 0, 0);
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];

    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)) {
        [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
    self.redditPosts = [NSMutableArray new];
    availableOptions = @[@"release", @"update", @"upcoming", @"news"];
    defaults = [NSUserDefaults standardUserDefaults];
    self.batchLoadCount = 500;
    [self refreshTable];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self registerView];
}

- (void)applyLocalization {
    // This isn't exactly "best practice", but this way the text in IB isn't useless.
    self.navigationItem.title = NSLocalizedString([self.navigationItem.title capitalizedString], @"");
}

//- (void)startSettingHeader  {
//    self.tableView.tableHeaderView.frame = CGRectMake(self.tableView.tableHeaderView.frame.origin.x, self.tableView.tableHeaderView.frame.origin.y, self.tableView.tableHeaderView.frame.size.width, CGFLOAT_MIN);
//    if ([defaults boolForKey:wantsNewsKey]) {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            // [self retrieveNewsJson];
//            [self kickStartReddit];
//        });
//    }
//}
//
//- (void)kickStartReddit {
//    NSDate *creationDate = [defaults objectForKey:@"redditCheck"];
//    if (!creationDate) {
//        [self getRedditToken];
//    } else {
//        double seconds = [[NSDate date] timeIntervalSinceDate:creationDate];
//        if (seconds > 3500) {
//            [self getRedditToken];
//        } else {
//            [self retrieveNewsJson];
//        }
//    }
//}
//
//- (void)getRedditToken {
//    NSURL *checkingURL = [NSURL URLWithString:@"https://ssl.reddit.com/api/v1/access_token"];
//    NSMutableURLRequest *request = [NSMutableURLRequest new];
//    [request setURL:checkingURL];
//    [request setHTTPMethod:@"POST"];
//    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
//    // NSString *authString = @"Basic YnllM25VQzk1VUhNRlE6IA==";
//    [request setValue:[NSString stringWithFormat:@"Zebra %@ iOS:%@", PACKAGE_VERSION, [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
//    [request setValue:@"Basic ZGZmVWtsVG9WY19ZV1E6IA==" forHTTPHeaderField:@"Authorization"];
//    NSString *string = @"grant_type=https://oauth.reddit.com/grants/installed_client&device_id=DO_NOT_TRACK_THIS_DEVICE";
//    [request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
//    NSURLSession *session = [NSURLSession sharedSession];
//    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        if (data) {
//            // NSLog(@"ZEBRA FINISHED THING %@", [data class]);
//            NSError *error2;
//            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error2];
//            // NSLog(@"ZEBRA DICT %@", dictionary);
//            [self->defaults setObject:[dictionary objectForKey:@"access_token"] forKey:@"redditToken"];
//            [self->defaults setObject:[NSDate date] forKey:@"redditCheck"];
//            [self->defaults synchronize];
//            [self retrieveNewsJson];
//        }
//        if (error) {
//            ZBLog(@"[Zebra] Error getting reddit token: %@", error);
//        }
//    }] resume];
//}
//
//- (void)retrieveNewsJson {
//    [self.redditPosts removeAllObjects];
//    NSMutableURLRequest *request = [NSMutableURLRequest new];
//    [request setURL:[NSURL URLWithString:@"https://oauth.reddit.com/r/jailbreak"]];
//    [request setHTTPMethod:@"GET"];
//    // [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
//    [request setValue:[NSString stringWithFormat:@"Zebra %@, iOS %@", PACKAGE_VERSION, [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
//    [request setValue:[NSString stringWithFormat:@"Bearer %@", [defaults valueForKey:@"redditToken"]] forHTTPHeaderField:@"Authorization"];
//    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        if (data) {
//            //NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
//            NSError *err;
//            ZBRedditPosts *redditPosts = [ZBRedditPosts fromData:data error:&err];
//            NSLog(@"Hello %@", redditPosts.kind);
//            for (ZBChild *child in redditPosts.data.children) {
//                if (child.data.title != nil) {
//                    NSArray *post = [self getTags:child.data.title];
//                    for (NSString *string in self->availableOptions) {
//                        if ([post containsObject:string] && ![self.redditPosts containsObject:child.data]) {
//                            [self.redditPosts addObject:child.data];
//                            // NSLog(@"redditposts %@", self.redditPosts);
//                        }
//                    }
//                }
//            }
//        }
//        if (error) {
//            ZBLog(@"[Zebra] Error retrieving news JSON %@", error);
//        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // [self animateTable];
//            [self createHeader];
//        });
//    }] resume];
//}
//
//- (void)createHeader {
//    [self.tableView beginUpdates];
//    [self.collectionView reloadData];
//    [UIView animateWithDuration:.25f animations:^{
//        self.tableView.tableHeaderView.frame = CGRectMake(self.tableView.tableHeaderView.frame.origin.x, self.tableView.tableHeaderView.frame.origin.y, self.tableView.tableHeaderView.frame.size.width, 180);
//    }];
//    [self.tableView endUpdates];
//}
//
//- (void)hideHeader {
//    [self.tableView beginUpdates];
//    [UIView animateWithDuration:.25f animations:^{
//        self.tableView.tableHeaderView.frame = CGRectMake(self.tableView.tableHeaderView.frame.origin.x, self.tableView.tableHeaderView.frame.origin.y, self.tableView.tableHeaderView.frame.size.width, 0);
//    }];
//    [self.collectionView reloadData];
//    [self.tableView endUpdates];
//}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (void)updateSections {
    self.tableData = [self partitionObjects:packages collationStringSelector:@selector(lastSeenDate)];
}

- (void)refreshTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->packages = [self.databaseManager packagesFromRepo:NULL inSection:NULL numberOfPackages:[self useBatchLoad] ? self.batchLoadCount : -1 startingAt:0];
        self->databaseRow = self.batchLoadCount - 1;
        self->totalNumberOfPackages = [self.databaseManager numberOfPackagesInRepo:NULL section:NULL];
        self->numberOfPackages = (int)[self->packages count];
        self.batchLoad = YES;
        self.continueBatchLoad = self.batchLoad;
        [self updateSections];
        [self.tableView reloadData];
    });
}

- (void)loadNextPackages {
    if (!self.continueBatchLoad || self.isPerformingBatchLoad) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->databaseRow < self->totalNumberOfPackages) {
            self.isPerformingBatchLoad = YES;
            NSArray *nextPackages = [self.databaseManager packagesFromRepo:NULL inSection:NULL numberOfPackages:self.batchLoadCount startingAt:self->databaseRow];
            if (nextPackages.count == 0) {
                self.continueBatchLoad = self.isPerformingBatchLoad = NO;
                return;
            }
            self->packages = [self->packages arrayByAddingObjectsFromArray:nextPackages];
            self->numberOfPackages = (int)[self->packages count];
            self->databaseRow += self.batchLoadCount;
            [self updateSections];
            [self.tableView reloadData];
            self.isPerformingBatchLoad = NO;
        }
    });
}

#pragma mark - Table view data source

- (NSArray <ZBPackage *> *)objectAtSection:(NSInteger)section {
    if ([self.tableData count] == 0)
        return nil;
    return [self.tableData objectAtIndex:section];
}

- (ZBPackage *)packageAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = [self objectAtSection:indexPath.section][indexPath.row];
    return package;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self tableView:tableView numberOfRowsInSection:section] ? 30 : 0;
}

- (NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector {
    sectionIndexTitles = [NSMutableArray array];
    return [ZBPackagePartitioner partitionObjects:array collationStringSelector:selector sectionIndexTitles:sectionIndexTitles packages:packages type:ZBSortingTypeDate];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([[self objectAtSection:section] count]) {
        return [ZBPackagePartitioner titleForHeaderInDateSection:section sectionIndexTitles:sectionIndexTitles];
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sectionIndexTitles count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self objectAtSection:section] count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(ZBPackageTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = [self packageAtIndexPath:indexPath];
    [cell updateData:package];
    if (self.batchLoad && self.continueBatchLoad && numberOfPackages != totalNumberOfPackages) {
        NSInteger sectionsAmount = [tableView numberOfSections];
        NSInteger rowsAmount = [tableView numberOfRowsInSection:indexPath.section];
        if ((indexPath.section == sectionsAmount - 1) && (indexPath.row == rowsAmount - 1)) {
            [self loadNextPackages];
        }
    }
}

- (ZBPackageTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
    [cell setColors];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"seguePackagesToPackageDepiction" sender:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.font = [UIFont boldSystemFontOfSize:15];
//    header.textLabel.textColor = [UIColor cellPrimaryTextColor];
    header.tintColor = [UIColor clearColor];
    [(UIView *)[header valueForKey:@"_backgroundView"] setBackgroundColor:[UIColor clearColor]];
}

#pragma mark - Swipe actions

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = [self packageAtIndexPath:indexPath];
    return [ZBPackageActionsManager rowActionsForPackage:package indexPath:indexPath viewController:self parent:nil completion:^(void) {
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView setEditing:NO animated:YES];
}

#pragma mark - Navigation

- (void)setDestinationVC:(NSIndexPath *)indexPath destination:(ZBPackageDepictionViewController *)destination {

    ZBPackage *package = [self packageAtIndexPath:indexPath];
    ZBPackage *candidate = [package installableCandidate];

    destination.package = candidate ? candidate : package;
    destination.parent = self;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"seguePackagesToPackageDepiction"]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = sender;
        [self setDestinationVC:indexPath destination:destination];
//        destination.view.backgroundColor = [UIColor tableViewBackgroundColor];
    }
}

- (UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    ZBPackageTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    previewingContext.sourceRect = cell.frame;
    ZBPackageDepictionViewController *packageDepictionVC = (ZBPackageDepictionViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];

    [self setDestinationVC:indexPath destination:packageDepictionVC];
    return packageDepictionVC;
//    else {
//        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
//        ZBNewsCollectionViewCell *cell = (ZBNewsCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
//
//        NSURL *url = [cell redditLink];
//        SFSafariViewController *sfVC = [[SFSafariViewController alloc] initWithURL:url];
//
//        return sfVC;
//    }
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {

    if ([viewControllerToCommit isKindOfClass:[SFSafariViewController class]]) {
        [self.navigationController presentViewController:viewControllerToCommit animated:true completion:nil];
    }
    else {
        [self.navigationController pushViewController:viewControllerToCommit animated:YES];
    }
}

- (void)darkMode:(NSNotification *)notif {
    [self.tableView reloadData];
    self.tableView.sectionIndexColor = [UIColor tintColor];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
}

#pragma mark - SFSafariViewController delegate methods
- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
    // Load finished
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    // Done button pressed
}

#pragma mark - Analytics

- (void)registerView {
    NSString *screenName = self.title;
    NSString *screenClass = [[self classForCoder] description];
    [FIRAnalytics setScreenName:screenName screenClass:screenClass];
}

@end
