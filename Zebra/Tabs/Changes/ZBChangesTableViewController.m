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
#import "ZBChangesTableViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActionsManager.h>
#import <Packages/Views/ZBPackageTableViewCell.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import "ZBRedditPosts.h"
@import SDWebImage;

@interface ZBChangesTableViewController () {
    NSUserDefaults *defaults;
    NSArray *packages;
    NSArray *availableOptions;
    NSArray *sectionIndexTitles;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleNews) name:@"toggleNews" object:nil];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"ZBNewsCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"newsCell"];
    [self.collectionView setContentInset:UIEdgeInsetsMake(0.f, 15.f, 0.f, 15.f)];
    [self.collectionView setShowsHorizontalScrollIndicator:FALSE];
    [self.collectionView setBackgroundColor:[UIColor tableViewBackgroundColor]];
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
    [self startSettingHeader];
    self.batchLoadCount = 500;
    [self refreshTable];
}

- (void)startSettingHeader  {
    self.tableView.tableHeaderView.frame = CGRectMake(self.tableView.tableHeaderView.frame.origin.x, self.tableView.tableHeaderView.frame.origin.y, self.tableView.tableHeaderView.frame.size.width, CGFLOAT_MIN);
    if ([defaults boolForKey:wantsNewsKey]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // [self retrieveNewsJson];
            [self kickStartReddit];
        });
    }
}

- (void)kickStartReddit {
    NSDate *creationDate = [defaults objectForKey:@"redditCheck"];
    if (!creationDate) {
        [self getRedditToken];
    } else {
        double seconds = [[NSDate date] timeIntervalSinceDate:creationDate];
        if (seconds > 3500) {
            [self getRedditToken];
        } else {
            [self retrieveNewsJson];
        }
    }
}

- (void)getRedditToken {
    NSURL *checkingURL = [NSURL URLWithString:@"https://ssl.reddit.com/api/v1/access_token"];
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:checkingURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    // NSString *authString = @"Basic YnllM25VQzk1VUhNRlE6IA==";
    [request setValue:[NSString stringWithFormat:@"Zebra %@ iOS:%@", PACKAGE_VERSION, [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"Basic ZGZmVWtsVG9WY19ZV1E6IA==" forHTTPHeaderField:@"Authorization"];
    NSString *string = @"grant_type=https://oauth.reddit.com/grants/installed_client&device_id=DO_NOT_TRACK_THIS_DEVICE";
    [request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            // NSLog(@"ZEBRA FINISHED THING %@", [data class]);
            NSError *error2;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error2];
            // NSLog(@"ZEBRA DICT %@", dictionary);
            [self->defaults setObject:[dictionary objectForKey:@"access_token"] forKey:@"redditToken"];
            [self->defaults setObject:[NSDate date] forKey:@"redditCheck"];
            [self->defaults synchronize];
            [self retrieveNewsJson];
        }
        if (error) {
            ZBLog(@"[Zebra] Error getting reddit token: %@", error);
        }
    }] resume];
}

- (void)retrieveNewsJson {
    [self.redditPosts removeAllObjects];
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:[NSURL URLWithString:@"https://oauth.reddit.com/r/jailbreak"]];
    [request setHTTPMethod:@"GET"];
    // [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[NSString stringWithFormat:@"Zebra %@, iOS %@", PACKAGE_VERSION, [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", [defaults valueForKey:@"redditToken"]] forHTTPHeaderField:@"Authorization"];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            //NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSError *err;
            ZBRedditPosts *redditPosts = [ZBRedditPosts fromData:data error:&err];
            NSLog(@"Hello %@", redditPosts.kind);
            for (ZBChild *child in redditPosts.data.children) {
                if (child.data.title != nil) {
                    NSArray *post = [self getTags:child.data.title];
                    for (NSString *string in self->availableOptions) {
                        if ([post containsObject:string] && ![self.redditPosts containsObject:child.data]) {
                            [self.redditPosts addObject:child.data];
                            // NSLog(@"redditposts %@", self.redditPosts);
                        }
                    }
                }
            }
        }
        if (error) {
            ZBLog(@"[Zebra] Error retrieving news JSON %@", error);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            // [self animateTable];
            [self createHeader];
        });
    }] resume];
}

- (void)createHeader {
    [self.tableView beginUpdates];
    [self.collectionView reloadData];
    [UIView animateWithDuration:.25f animations:^{
        self.tableView.tableHeaderView.frame = CGRectMake(self.tableView.tableHeaderView.frame.origin.x, self.tableView.tableHeaderView.frame.origin.y, self.tableView.tableHeaderView.frame.size.width, 180);
    }];
    [self.tableView endUpdates];
}

- (void)hideHeader {
    [self.tableView beginUpdates];
    [UIView animateWithDuration:.25f animations:^{
        self.tableView.tableHeaderView.frame = CGRectMake(self.tableView.tableHeaderView.frame.origin.x, self.tableView.tableHeaderView.frame.origin.y, self.tableView.tableHeaderView.frame.size.width, 0);
    }];
    [self.collectionView reloadData];
    [self.tableView endUpdates];
}

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

- (id)objectAtSection:(NSInteger)section {
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
    NSMutableDictionary <NSDate *, NSMutableArray *> *partitions = [NSMutableDictionary new];
    for (ZBPackage *package in packages) {
        NSDate *groupedDate = package.lastSeenDate;
        if (groupedDate == nil)
            continue;
        if (partitions[groupedDate] == nil) {
            partitions[groupedDate] = [NSMutableArray array];
        }
        [partitions[groupedDate] addObject:package];
    }
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
    sectionIndexTitles = [[partitions allKeys] sortedArrayUsingDescriptors:@[dateDescriptor]];
    NSUInteger sectionCount = [sectionIndexTitles count];
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
    for (NSDate *date in sectionIndexTitles) {
        [sections addObject:partitions[date]];
    }
    return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([(NSArray *)[self objectAtSection:section] count]) {
        return [NSDateFormatter localizedStringFromDate:sectionIndexTitles[section] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sectionIndexTitles count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [(NSArray *)[self objectAtSection:section] count];
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
    header.textLabel.textColor = [UIColor cellPrimaryTextColor];
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
        destination.view.backgroundColor = [UIColor tableViewBackgroundColor];
    }
}

- (UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    ZBPackageTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    previewingContext.sourceRect = cell.frame;
    ZBPackageDepictionViewController *packageDepictionVC = (ZBPackageDepictionViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
    
    [self setDestinationVC:indexPath destination:packageDepictionVC];
    return packageDepictionVC;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

- (void)darkMode:(NSNotification *)notif {
    [self.tableView reloadData];
    self.tableView.sectionIndexColor = [UIColor tintColor];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
    [self.collectionView setBackgroundColor:[UIColor tableViewBackgroundColor]];
}

#pragma mark News
- (UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ZBNewsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"newsCell" forIndexPath:indexPath];
    ZBChildData *post = [self.redditPosts objectAtIndex:indexPath.row];
    NSURL *url;
    if (post.title != nil) {
        NSString *text = post.title;
        text = [text stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        text = [text stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        text = [text stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        cell.postTitle.text = text;
        
        NSMutableArray *tags = [NSMutableArray new];
        for (NSString *string in [self getTags:post.title]) {
            if ([availableOptions containsObject:string]) {
                [tags addObject:string];
            }
        }
        cell.postTag.text = [tags componentsJoinedByString:@", "];
        cell.postTag.text = [cell.postTag.text capitalizedString];
    } else {
        cell.postTitle.text = @"Error";
    }
    if (post.url != nil) {
        // [cell setRedditLink:[NSURL URLWithString:[dict objectForKey:@"url"]]];
        [cell setRedditLink:[NSURL URLWithString:[NSString stringWithFormat:@"https://reddit.com/%@", post.identifier]]];
        [cell setRedditID:post.identifier];
    } else {
        [cell setRedditLink:[NSURL URLWithString:@"https://reddit.com/r/jailbreak"]];
    }
    
    //NSDictionary *previews = [dict objectForKey:@"preview"];
    if (post.preview.images.count) {
        //NSArray *images = [previews objectForKey:@"images"];
        //NSDictionary *imageDict = [images firstObject];
        ZBImage *first = post.preview.images[0];
        // ZBLog(@"IMAGE %@", imageDict);
        if (first.source != nil) {
            NSString *link = first.source.url;
            link = [link stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
            url = [NSURL URLWithString:link];
            /*url = [NSURL URLWithString:[[imageDict valueForKeyPath:@"source.url"] stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"]];*/
        }
    }
    
    //if ([dict valueForKey:@"thumbnail"] != [NSNull null] && ([[dict valueForKey:@"thumbnail"] isEqualToString:@"self"] || [[dict valueForKey:@"thumbnail"] isEqualToString:@"default"] || [[dict valueForKey:@"thumbnail"] isEqualToString:@"nsfw"])) {
    
    if (url) {
        [cell.backgroundImage sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"Unknown"]];
    }else if (post.thumbnail != nil && ([post.thumbnail isEqualToString:@"self"] || [post.thumbnail isEqualToString:@"default"] || [post.thumbnail isEqualToString:@"nsfw"])) {
        [cell.backgroundImage setImage:[UIImage imageNamed:@"banner"]];
    } else {
        [cell.backgroundImage sd_setImageWithURL:[NSURL URLWithString:post.thumbnail] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    }
    return cell;
}

- (NSString *)stripTag:(NSString *)title {
    NSArray *authorName = [title componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableArray *cleanedStrings = [NSMutableArray new];
    for(NSString *cut in authorName) {
        if (![cut hasPrefix:@"["] && ![cut hasSuffix:@"]"]) {
            [cleanedStrings addObject:cut];
        } 
    }
    
    return [cleanedStrings componentsJoinedByString:@" "];
}

- (NSArray *)getTags:(NSString *)body {
    body = [body lowercaseString];
    NSArray *authorName = [body componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableArray *cleanedStrings = [NSMutableArray new];
    for(NSString *cut in authorName) {
        if ([cut hasPrefix:@"["] && [cut hasSuffix:@"]"]) {
            NSString *cutCopy = [cut copy];
            cutCopy = [cut substringFromIndex:1];
            cutCopy = [cutCopy substringWithRange:NSMakeRange(0, cutCopy.length - 1)];
            if ([cutCopy containsString:@"]["]) {
                [cleanedStrings addObjectsFromArray:[cutCopy componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            } else {
                [cleanedStrings addObject:cutCopy];
            }
        }
    }
    return cleanedStrings;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(263, 148);
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.redditPosts.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UIApplication *application = [UIApplication sharedApplication];
    ZBNewsCollectionViewCell *cell = (ZBNewsCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if ([application canOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"apollo://reddit.com/%@", cell.redditID]]]) {
        [application openURL:[NSURL URLWithString:[NSString stringWithFormat:@"apollo://reddit.com/%@", cell.redditID]]];
    } else {
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:cell.redditLink entersReaderIfAvailable:NO];
        safariVC.delegate = self;
        if (@available(iOS 10.0, *)) {
            [safariVC setPreferredBarTintColor:[UIColor tableViewBackgroundColor]];
            [safariVC setPreferredControlTintColor:[UIColor tintColor]];
        } else {
            [safariVC.view setTintColor:[UIColor tintColor]];
        }
        [self presentViewController:safariVC animated:YES completion:nil];
    }
}

- (void)toggleNews {
    if ([defaults boolForKey:wantsNewsKey]) {
        [self retrieveNewsJson];
    } else {
        [self.redditPosts removeAllObjects];
        [self hideHeader];
        // [self animateTable];
    }
}

#pragma mark - SFSafariViewController delegate methods
- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
    // Load finished
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    // Done button pressed
}

@end
