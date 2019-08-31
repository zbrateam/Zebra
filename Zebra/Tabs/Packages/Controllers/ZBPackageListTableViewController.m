//
//  ZBPackageListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <ZBAppDelegate.h>
#import <ZBLog.h>
#import <ZBTab.h>
#import "ZBPackageListTableViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActionsManager.h>
#import <Queue/ZBQueue.h>
#import <ZBTabBarController.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Packages/Views/ZBPackageTableViewCell.h>
#import <UIColor+GlobalColors.h>
#import "ZBDevice.h"

typedef enum {
    ZBSortingTypeABC,
    ZBSortingTypeDate
} ZBSortingType;

@interface ZBPackageListTableViewController () {
    ZBSortingType selectedSortingType;
    NSArray <ZBPackage *> *packages;
    NSArray <ZBPackage *> *sortedPackages;
    NSMutableArray <ZBPackage *> *updates;
    NSMutableArray <ZBPackage *> *ignoredUpdates;
    NSMutableArray *sectionIndexTitles;
    UIBarButtonItem *queueButton;
    UIBarButtonItem *clearButton;
    BOOL needsUpdatesSection;
    BOOL needsIgnoredUpdatesSection;
    BOOL isRefreshingTable;
    int totalNumberOfPackages;
    int numberOfPackages;
    int databaseRow;
}
@end

@implementation ZBPackageListTableViewController

@synthesize repo;
@synthesize section;

- (BOOL)useBatchLoad {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    selectedSortingType = [[NSUserDefaults standardUserDefaults] boolForKey:@"sortPackagesByRecent"] ? ZBSortingTypeDate : ZBSortingTypeABC;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.contentInset = UIEdgeInsetsMake(5, 0, 0, 0);
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)) {
        [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshTable];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (void)configureNavigationButtons {
    if ([repo repoID] == 0) {
        [self configureUpgradeButton];
        [self configureQueueOrShareButton];
    } else {
        [self configureLoadMoreButton];
    }
    [self configureSegmentedController];
}

- (void)updateCollation {
    self.tableData = [self partitionObjects:packages collationStringSelector:@selector(name)];
}

- (void)refreshTable {
    if (isRefreshingTable)
        return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self->repo repoID] == 0) {
            self->isRefreshingTable = YES;
            self->packages = [self.databaseManager installedPackages];
            self->updates = [self.databaseManager packagesWithUpdates];
            self->ignoredUpdates = [self.databaseManager packagesWithIgnoredUpdates];
            
            NSUInteger totalUpdates = self->updates.count;
            self->needsUpdatesSection = totalUpdates != 0;
            self->needsIgnoredUpdatesSection = self->ignoredUpdates.count != 0;
            UITabBarItem *packagesTabBarItem = [self.tabBarController.tabBar.items objectAtIndex:ZBTabPackages];
            [packagesTabBarItem setBadgeValue:totalUpdates ? [NSString stringWithFormat:@"%lu", (unsigned long)totalUpdates] : nil];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:totalUpdates];
            
            self->isRefreshingTable = NO;
        } else {
            self.batchLoadCount = 500;
            self->packages = [self.databaseManager packagesFromRepo:self->repo inSection:self->section numberOfPackages:[self useBatchLoad] ? self.batchLoadCount : -1 startingAt:0];
            self->databaseRow = self.batchLoadCount - 1;
            self->totalNumberOfPackages = [self.databaseManager numberOfPackagesInRepo:self->repo section:self->section];
            self.continueBatchLoad = self.batchLoad = YES;
            [self configureLoadMoreButton];
        }
        if (self->selectedSortingType == ZBSortingTypeDate) {
            self->sortedPackages = [self->packages sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                NSDate *first = [(ZBPackage *)a installedDate];
                NSDate *second = [(ZBPackage *)b installedDate];
                return [second compare:first];
            }];
        } else {
            self->sortedPackages = nil;
        }
        [self configureNavigationButtons];
        self->numberOfPackages = (int)[self->packages count];
        
        [self updateCollation];
        [self.tableView reloadData];
    });
}

- (void)loadNextPackages {
    if (!self.continueBatchLoad || self.isPerformingBatchLoad) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->numberOfPackages < self->totalNumberOfPackages) {
            self.isPerformingBatchLoad = YES;
            NSArray *nextPackages = [self.databaseManager packagesFromRepo:self->repo inSection:self->section numberOfPackages:self.batchLoadCount startingAt:self->databaseRow];
            if (nextPackages.count == 0) {
                self.continueBatchLoad = self.isPerformingBatchLoad = NO;
            } else {
                self->packages = [self.databaseManager cleanUpDuplicatePackages:[self->packages arrayByAddingObjectsFromArray:nextPackages]];
                self->numberOfPackages = (int)[self->packages count];
                self->databaseRow += self.batchLoadCount;
                [self updateCollation];
                [self.tableView reloadData];
                self.isPerformingBatchLoad = NO;
            }
        } else {
            self.continueBatchLoad = self.isPerformingBatchLoad = NO;
        }
        [self configureLoadMoreButton];
    });
}

- (void)configureUpgradeButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->needsUpdatesSection) {
            UIBarButtonItem *updateButton = [[UIBarButtonItem alloc] initWithTitle:@"Upgrade All" style:UIBarButtonItemStylePlain target:self action:@selector(upgradeAll)];
            self.navigationItem.rightBarButtonItem = updateButton;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    });
}

- (void)configureLoadMoreButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.continueBatchLoad) {
            if (self->totalNumberOfPackages) {
                UIBarButtonItem *loadButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%.0f%% Loaded", MIN(100, (double)(self->numberOfPackages * 100) / self->totalNumberOfPackages)] style:UIBarButtonItemStylePlain target:self action:@selector(loadNextPackages)];
                self.navigationItem.rightBarButtonItem = loadButton;
            }
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    });
}

- (void)configureSegmentedController {
    self.navigationItem.leftBarButtonItems = nil;
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"ABC", @"Date"]];
    segmentedControl.selectedSegmentIndex = (NSInteger)self->selectedSortingType;
    [segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentedControl;
}

- (void)configureQueueOrShareButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[ZBQueue sharedInstance] hasObjects]) {
            self->queueButton = [[UIBarButtonItem alloc] initWithTitle:@"Queue" style:UIBarButtonItemStylePlain target:self action:@selector(presentQueue)];
            self->clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(askClearQueue)];
            self.navigationItem.leftBarButtonItems = @[ self->queueButton, self->clearButton ];
        } else {
            self->queueButton = self->clearButton = nil;
            self.navigationItem.leftBarButtonItems = nil;
            UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sharePackages)];
            self.navigationItem.leftBarButtonItem = shareButton;
        }
    });
}

- (void)presentQueue {
    [ZBPackageActionsManager presentQueue:self parent:nil];
}

- (void)askClearQueue {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Zebra" message:@"Are you sure you want to clear Queue?" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *clearAction = [UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self clearQueue];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL];
    [alert addAction:clearAction];
    [alert addAction:cancelAction];
    
    alert.popoverPresentationController.barButtonItem = self->clearButton;
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clearQueue {
    [[ZBQueue sharedInstance] clearQueue];
    [self refreshTable];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBUpdateQueueBar" object:nil];
}

- (void)sharePackages {
    NSArray *packages = [[self.databaseManager installedPackages] copy];
    NSMutableArray *packageIds = [NSMutableArray new];
    for (ZBPackage *package in packages) {
        if (package.identifier) {
            [packageIds addObject:package.identifier];
        }
    }
    if ([packageIds count]) {
        packageIds = [[packageIds sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
        NSString *fullList = [packageIds componentsJoinedByString:@"\n"];
        NSArray *share = @[fullList];
        UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:share applicationActivities:nil];
        [self presentActivityController:controller];
    }
}

// Share Sheet
- (void)presentActivityController:(UIActivityViewController *)controller {
    
    // for iPad: make the presentation a Popover
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:controller animated:YES completion:nil];
    
    UIPopoverPresentationController *popController = [controller popoverPresentationController];
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popController.barButtonItem = self.navigationItem.leftBarButtonItem;
    
    // access the completion handler
    controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *error) {
        // react to the completion
        if (completed) {
            // user shared an item
            ZBLog(@"We used activity type %@", activityType);
        } else {
            // user cancelled
            ZBLog(@"We didn't want to share anything after all.");
        }
        
        if (error) {
            ZBLog(@"An Error occured: %@, %@", error.localizedDescription, error.localizedFailureReason);
        }
    };
}

- (void)upgradeAll {
    ZBQueue *queue = [ZBQueue sharedInstance];
    [queue addPackages:updates toQueue:ZBQueueTypeUpgrade];
    [self presentQueue];
}

- (ZBPackage *)packageAtIndexPath:(NSIndexPath *)indexPath {
    if (needsUpdatesSection && indexPath.section == 0) {
        return [updates objectAtIndex:indexPath.row];
    }
    if (needsIgnoredUpdatesSection && indexPath.section == needsUpdatesSection) {
        return [ignoredUpdates objectAtIndex:indexPath.row];
    }
    if (selectedSortingType == ZBSortingTypeABC) {
        ZBPackage *package = [self objectAtSection:indexPath.section][indexPath.row];
        return package;
    }
    return sortedPackages[indexPath.row];
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)segmentedControl {
    selectedSortingType = (ZBSortingType)segmentedControl.selectedSegmentIndex;
    [[NSUserDefaults standardUserDefaults] setBool:selectedSortingType == ZBSortingTypeDate forKey:@"sortPackagesByRecent"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTable];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (selectedSortingType == ZBSortingTypeABC) {
        return [sectionIndexTitles count] + needsUpdatesSection + needsIgnoredUpdatesSection;
    }
    return 1 + needsUpdatesSection + needsIgnoredUpdatesSection;
}

- (NSInteger)trueSection:(NSInteger)section {
    return section - needsUpdatesSection - needsIgnoredUpdatesSection;
}

- (id)objectAtSection:(NSInteger)section {
    if ([self.tableData count] == 0)
        return nil;
    NSInteger trueSection = [self trueSection:section];
    return trueSection < [self.tableData count] ? [self.tableData objectAtIndex:trueSection] : nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (needsUpdatesSection && section == 0) {
        return updates.count;
    }
    if (needsIgnoredUpdatesSection && section == needsUpdatesSection) {
        return ignoredUpdates.count;
    }
    if (self->selectedSortingType == ZBSortingTypeABC) {
        return [[self objectAtSection:section] count];
    }
    return sortedPackages.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(ZBPackageTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = [self packageAtIndexPath:indexPath];
    [cell updateData:package];
    if ([repo repoID] != 0 && self.batchLoad && self.continueBatchLoad && numberOfPackages != totalNumberOfPackages) {
        NSInteger sectionsAmount = [tableView numberOfSections];
        NSInteger rowsAmount = [tableView numberOfRowsInSection:indexPath.section];
        if ((indexPath.section == sectionsAmount - 1) && (indexPath.row == rowsAmount - 1)) {
            [self loadNextPackages];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
    [cell setColors];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"seguePackagesToPackageDepiction" sender:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([[self objectAtSection:section] count]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.font = [UIFont boldSystemFontOfSize:15];
        header.textLabel.textColor = [UIColor cellPrimaryTextColor];
        header.tintColor = [UIColor clearColor];
        [(UIView *)[header valueForKey:@"_backgroundView"] setBackgroundColor:[UIColor clearColor]];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    BOOL isUpdateSection = [repo repoID] == 0 && needsUpdatesSection && section == 0;
    BOOL isIgnoredUpdateSection = [repo repoID] == 0 && needsIgnoredUpdatesSection && section == needsUpdatesSection;
    BOOL hasDataInSection = !isUpdateSection && !isIgnoredUpdateSection && [[self objectAtSection:section] count];
    if (isUpdateSection || isIgnoredUpdateSection || hasDataInSection) {
        if (isUpdateSection) {
            return [NSString stringWithFormat:@"Available Upgrades (%lu)", (unsigned long)updates.count];
        }
        if (isIgnoredUpdateSection) {
            return [NSString stringWithFormat:@"Ignored Upgrades (%lu)", (unsigned long)ignoredUpdates.count];
        }
        if (selectedSortingType == ZBSortingTypeABC && hasDataInSection) {
            return [self sectionIndexTitlesForTableView:tableView][[self trueSection:section]];
        }
        if (selectedSortingType == ZBSortingTypeDate) {
            return @"Recent";
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self tableView:tableView numberOfRowsInSection:section] ? 30 : 0;
}

- (NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector {
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    sectionIndexTitles = [NSMutableArray arrayWithArray:[collation sectionIndexTitles]];
    NSInteger sectionCount = [[collation sectionTitles] count];
    NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
    for (int i = 0; i < sectionCount; ++i) {
        [unsortedSections addObject:[NSMutableArray array]];
    }
    for (id object in array) {
        NSInteger index = [collation sectionForObject:object collationStringSelector:selector];
        [[unsortedSections objectAtIndex:index] addObject:object];
    }
    NSUInteger lastIndex = 0;
    NSMutableIndexSet *sectionsToRemove = [NSMutableIndexSet indexSet];
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
    for (NSMutableArray *section in unsortedSections) {
        if ([section count] == 0) {
            NSRange range = NSMakeRange(lastIndex, [unsortedSections count] - lastIndex);
            [sectionsToRemove addIndex:[unsortedSections indexOfObject:section inRange:range]];
            lastIndex = [sectionsToRemove lastIndex] + 1;
        } else {
            [sections addObject:[collation sortedArrayFromArray:section collationStringSelector:selector]];
        }
    }
    [sectionIndexTitles removeObjectsAtIndexes:sectionsToRemove];
    return sections;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self->selectedSortingType == ZBSortingTypeABC) {
        return sectionIndexTitles;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index + needsUpdatesSection + needsIgnoredUpdatesSection;
}

#pragma mark - Swipe actions

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = [self packageAtIndexPath:indexPath];
    return [ZBPackageActionsManager rowActionsForPackage:package indexPath:indexPath viewController:self parent:nil completion:^(void) {
        [tableView reloadData];
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
        if (@available(iOS 11.0, *)) {
            destination.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
        }
        [self setDestinationVC:indexPath destination:destination];
        destination.view.backgroundColor = [UIColor tableViewBackgroundColor];
    }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
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
    [ZBDevice refreshViews];
    self.tableView.sectionIndexColor = [UIColor tintColor];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
    [self.navigationController.navigationBar setBarTintColor:nil];
}

@end
