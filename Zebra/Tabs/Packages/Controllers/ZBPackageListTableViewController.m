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
#import <ZBSettings.h>
#import <ZBPackagePartitioner.h>
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

@import FirebaseAnalytics;

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
    [self applyLocalization];

    selectedSortingType = [[NSUserDefaults standardUserDefaults] integerForKey:packageSortingKey];
    if (repo.repoID && selectedSortingType == ZBSortingTypeInstalledSize)
        selectedSortingType = ZBSortingTypeABC;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
//    self.tableView.contentInset = UIEdgeInsetsMake(5, 0, 0, 0);
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)) {
        [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
    
    self.section = [self.section stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

- (void)applyLocalization {
    // This isn't exactly "best practice", but this way the text in IB isn't useless.
    self.navigationItem.title = NSLocalizedString([self.navigationItem.title capitalizedString], @"");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshTable];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (void)layoutNavigationButtonsNormal {
    if ([repo repoID] == 0) {
        [self configureUpgradeButton];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sharePackages)];
            self.navigationItem.leftBarButtonItem = shareButton;
        });
    } else {
        [self configureLoadMoreButton];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.leftBarButtonItem = nil;
        });
    }
    [self configureSegmentedController];
}

- (void)layoutNavigationButtonsRefreshing {
    [super layoutNavigationButtonsRefreshing];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.rightBarButtonItem = nil;
    });
}

- (void)updateCollation {
    switch (selectedSortingType) {
        case ZBSortingTypeABC:
            self.tableData = [self partitionObjects:packages collationStringSelector:@selector(name)];
            break;
        case ZBSortingTypeDate:
            self.tableData = [self partitionObjects:packages collationStringSelector:repo.repoID ? @selector(lastSeenDate) : @selector(installedDate)];
            break;
        default:
            break;
    }
}

- (void)refreshTable {
    if (isRefreshingTable)
        return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self->repo repoID] == 0) {
            self->isRefreshingTable = YES;
            self->packages = [self.databaseManager installedPackages:false];
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
        if (self->selectedSortingType == ZBSortingTypeInstalledSize) {
            self->sortedPackages = [self->packages sortedArrayUsingComparator:^NSComparisonResult(ZBPackage *a, ZBPackage *b) {
                NSInteger sizeA = [a installedSize];
                NSInteger sizeB = [b installedSize];
                return sizeB - sizeA;
            }];
        } else {
            self->sortedPackages = nil;
        }
        [self layoutNavigationButtons];
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
            UIBarButtonItem *updateButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upgrade All", @"") style:UIBarButtonItemStylePlain target:self action:@selector(upgradeAll)];
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
                UIBarButtonItem *loadButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%.0f%% %@", MIN(100, (double)(self->numberOfPackages * 100) / self->totalNumberOfPackages), NSLocalizedString(@"Loaded", @"")] style:UIBarButtonItemStylePlain target:self action:@selector(loadNextPackages)];
                self.navigationItem.rightBarButtonItem = loadButton;
            }
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    });
}

- (void)configureSegmentedController {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *items = [@[NSLocalizedString(@"ABC", @""), NSLocalizedString(@"Date", @""), NSLocalizedString(@"Size", @"")] mutableCopy];
        if (self->repo.repoID)
            [items removeLastObject];
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
        segmentedControl.selectedSegmentIndex = self->selectedSortingType;
        [segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
        self.navigationItem.titleView = segmentedControl;
    });
}

- (void)presentQueue {
    [[ZBAppDelegate tabBarController] openQueue:YES];
}

- (void)askClearQueue {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Zebra" message:NSLocalizedString(@"Are you sure you want to clear Queue?", @"") preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *clearAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Clear", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self clearQueue];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:NULL];
    [alert addAction:clearAction];
    [alert addAction:cancelAction];
    
    alert.popoverPresentationController.barButtonItem = self->clearButton;
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clearQueue {
    [[ZBQueue sharedQueue] clear];
    [self refreshTable];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBUpdateQueueBar" object:nil];
}

- (void)sharePackages {
    NSArray *packages = [[self.databaseManager installedPackages:false] copy];
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
    ZBQueue *queue = [ZBQueue sharedQueue];
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
    if (selectedSortingType == ZBSortingTypeABC || selectedSortingType == ZBSortingTypeDate) {
        ZBPackage *package = [self objectAtSection:indexPath.section][indexPath.row];
        return package;
    }
    return sortedPackages[indexPath.row];
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)segmentedControl {
    selectedSortingType = (ZBSortingType)segmentedControl.selectedSegmentIndex;
    [[NSUserDefaults standardUserDefaults] setInteger:selectedSortingType forKey:packageSortingKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTable];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (selectedSortingType == ZBSortingTypeABC || selectedSortingType == ZBSortingTypeDate) {
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
    if (selectedSortingType == ZBSortingTypeABC || selectedSortingType == ZBSortingTypeDate) {
        return [[self objectAtSection:section] count];
    }
    return sortedPackages.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(ZBPackageTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = [self packageAtIndexPath:indexPath];
    [cell updateData:package calculateSize:selectedSortingType == ZBSortingTypeInstalledSize];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    BOOL isUpdateSection = [repo repoID] == 0 && needsUpdatesSection && section == 0;
    BOOL isIgnoredUpdateSection = [repo repoID] == 0 && needsIgnoredUpdatesSection && section == needsUpdatesSection;
    BOOL hasDataInSection = !isUpdateSection && !isIgnoredUpdateSection && [[self objectAtSection:section] count];
    if (isUpdateSection || isIgnoredUpdateSection || hasDataInSection) {
        if (isUpdateSection) {
            return [NSString stringWithFormat:@"%@ (%lu)", NSLocalizedString(@"Available Upgrades", @""), (unsigned long)updates.count];
        }
        if (isIgnoredUpdateSection) {
            return [NSString stringWithFormat:@"%@ (%lu)", NSLocalizedString(@"Ignored Upgrades", @""), (unsigned long)ignoredUpdates.count];
        }
        if (hasDataInSection) {
            NSInteger trueSection = [self trueSection:section];
            if (selectedSortingType == ZBSortingTypeABC)
                return [self sectionIndexTitlesForTableView:tableView][trueSection];
            if (selectedSortingType == ZBSortingTypeDate)
                return [ZBPackagePartitioner titleForHeaderInDateSection:trueSection sectionIndexTitles:sectionIndexTitles dateStyle:NSDateFormatterShortStyle timeStye:NSDateFormatterShortStyle];
        }
        if (selectedSortingType == ZBSortingTypeInstalledSize) {
            return @"Size";
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self tableView:tableView numberOfRowsInSection:section] ? 30 : 0;
}

- (NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector {
    sectionIndexTitles = [NSMutableArray array];
    return [ZBPackagePartitioner partitionObjects:array collationStringSelector:selector sectionIndexTitles:sectionIndexTitles packages:packages type:selectedSortingType];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (selectedSortingType == ZBSortingTypeABC)
        return sectionIndexTitles;
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
    BOOL isUpdateSection = [repo repoID] == 0 && needsUpdatesSection && section == 0;
    ZBPackage *candidate = isUpdateSection ? [[ZBDatabaseManager sharedInstance] topVersionForPackage:package] : [package installableCandidate];
    destination.package = candidate ? candidate : package;
    destination.parent = self;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"seguePackagesToPackageDepiction"] && [[segue destinationViewController] isKindOfClass:[ZBPackageDepictionViewController class]]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = sender;
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
