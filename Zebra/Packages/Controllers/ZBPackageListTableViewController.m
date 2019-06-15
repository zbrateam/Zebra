//
//  ZBPackageListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBPackageListTableViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActionsManager.h>
#import <Queue/ZBQueue.h>
#import <ZBTabBarController.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Packages/Helpers/ZBPackageTableViewCell.h>
#import <UIColor+GlobalColors.h>
#import <ZBAppDelegate.h>
#import <ZBTab.h>

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
@synthesize databaseManager;

- (id)init {
    self = [super init];
    
    if (self) {
        if (!databaseManager) {
            databaseManager = [ZBDatabaseManager sharedInstance];
        }
        selectedSortingType = ZBSortingTypeABC;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        if (!databaseManager) {
            databaseManager = [ZBDatabaseManager sharedInstance];
        }
        selectedSortingType = ZBSortingTypeABC;
    }
    
    return self;
}

- (BOOL)useBatchLoad {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"lightMode" object:nil];
    self.defaults = [NSUserDefaults standardUserDefaults];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.contentInset = UIEdgeInsetsMake(5, 0, 0, 0);
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)) {
        [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
    [self refreshTable];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (void)configureNavigationButtons {
    if ([repo repoID] == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addUpgradeButton];
            [self addQueueButtonOrSegmented];
        });
    }
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
            self->packages = [self->databaseManager installedPackages];
            self->updates = [self->databaseManager packagesWithUpdates];
            self->ignoredUpdates = [self->databaseManager packagesWithIgnoredUpdates];
            
            NSUInteger totalUpdates = self->updates.count;
            self->needsUpdatesSection = totalUpdates != 0;
            self->needsIgnoredUpdatesSection = self->ignoredUpdates.count != 0;
            UITabBarItem *packagesTabBarItem = [self.tabBarController.tabBar.items objectAtIndex:ZBTabPackages];
            [packagesTabBarItem setBadgeValue:totalUpdates ? [NSString stringWithFormat:@"%lu", (unsigned long)totalUpdates] : nil];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:totalUpdates];
            
            if (self->selectedSortingType == ZBSortingTypeDate) {
                self->sortedPackages = [self->packages sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                    NSDate *first = [(ZBPackage *)a installedDate];
                    NSDate *second = [(ZBPackage *)b installedDate];
                    return [second compare:first];
                }];
            }
            else {
                self->sortedPackages = nil;
            }
            [self configureNavigationButtons];
            self->isRefreshingTable = NO;
        }
        else {
            self.batchLoadCount = 500;
            self->packages = [self->databaseManager packagesFromRepo:self->repo inSection:self->section numberOfPackages:[self useBatchLoad] ? self.batchLoadCount : -1 startingAt:0];
            self->databaseRow = self.batchLoadCount - 1;
            if (self->section != NULL) {
                self->totalNumberOfPackages = [self->databaseManager numberOfPackagesInRepo:self->repo section:self->section];
            }
            else {
                self->totalNumberOfPackages = [self->databaseManager numberOfPackagesInRepo:self->repo section:NULL];
            }
            self.batchLoad = YES;
            self.continueBatchLoad = self.batchLoad;
        }
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
        if (self->databaseRow < self->totalNumberOfPackages) {
            self.isPerformingBatchLoad = YES;
            NSArray *nextPackages = [self->databaseManager packagesFromRepo:self->repo inSection:self->section numberOfPackages:self.batchLoadCount startingAt:self->databaseRow];
            if (nextPackages.count == 0) {
                self.continueBatchLoad = self.isPerformingBatchLoad = NO;
                return;
            }
            self->packages = [self->packages arrayByAddingObjectsFromArray:nextPackages];
            self->numberOfPackages = (int)[self->packages count];
            self->databaseRow += self.batchLoadCount;
            [self updateCollation];
            [self.tableView reloadData];
            self.isPerformingBatchLoad = NO;
        }
    });
}

- (void)addUpgradeButton {
    if (needsUpdatesSection) {
        UIBarButtonItem *updateButton = [[UIBarButtonItem alloc] initWithTitle:@"Upgrade All" style:UIBarButtonItemStylePlain target:self action:@selector(upgradeAll)];
        self.navigationItem.rightBarButtonItem = updateButton;
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)addQueueButtonOrSegmented {
    if ([[ZBQueue sharedInstance] hasObjects]) {
        UIBarButtonItem *queueButton = [[UIBarButtonItem alloc] initWithTitle:@"Queue" style:UIBarButtonItemStylePlain target:self action:@selector(presentQueue)];
        self.navigationItem.leftBarButtonItem = queueButton;
    }
    else {
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"ABC", @"Date"]];
        segmentedControl.selectedSegmentIndex = (NSInteger)self->selectedSortingType;
        [segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
        UIBarButtonItem *controlItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
        self.navigationItem.leftBarButtonItem = controlItem;
    }
}

- (void)presentQueue {
    [ZBPackageActionsManager presentQueue:self parent:nil];
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
    return [self.tableData objectAtIndex:[self trueSection:section]];
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
    if ([self.defaults boolForKey:@"darkMode"]) {
        cell.packageLabel.textColor = [UIColor whiteColor];//[UIColor cellPrimaryTextColor];
        cell.descriptionLabel.textColor = [UIColor lightGrayColor];//[UIColor cellSecondaryTextColor];
        cell.backgroundContainerView.backgroundColor = [UIColor colorWithRed:0.110 green:0.110 blue:0.114 alpha:1.0];//[UIColor cellBackgroundColor];
    } else {
        cell.packageLabel.textColor = [UIColor cellPrimaryTextColor];
        cell.descriptionLabel.textColor = [UIColor cellSecondaryTextColor];
        cell.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"seguePackagesToPackageDepiction" sender:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    BOOL isUpdateSection = [repo repoID] == 0 && needsUpdatesSection && section == 0;
    BOOL isIgnoredUpdateSection = [repo repoID] == 0 && needsIgnoredUpdatesSection && section == needsUpdatesSection;
    BOOL hasDataInSection = !isUpdateSection && !isIgnoredUpdateSection && [[self objectAtSection:section] count];
    if (isUpdateSection || isIgnoredUpdateSection || hasDataInSection) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0)];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 10, 18)];
        [label setFont:[UIFont boldSystemFontOfSize:15]];
        if (isUpdateSection) {
            [label setText:[NSString stringWithFormat:@"Available Upgrades (%lu)", (unsigned long)updates.count]];
        }
        else if (isIgnoredUpdateSection) {
            [label setText:[NSString stringWithFormat:@"Ignored Upgrades (%lu)", (unsigned long)ignoredUpdates.count]];
        }
        else if (selectedSortingType == ZBSortingTypeABC && hasDataInSection) {
            [label setText:[self sectionIndexTitlesForTableView:tableView][[self trueSection:section]]];
        }
        else if (selectedSortingType == ZBSortingTypeDate) {
            [label setText:@"Recent"];
        }
        
        if ([self.defaults boolForKey:@"darkMode"]) {
            [label setTextColor:[UIColor whiteColor]];
        } else {
            [label setTextColor:[UIColor cellPrimaryTextColor]];
        }
        
        [view addSubview:label];
        
        label.translatesAutoresizingMaskIntoConstraints = NO;
        
        // align label from the left and right
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[label]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
        
        // align label from the bottom
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-5-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
        
        return view;
    }
    else {
        return nil;
    }
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
        }
        else {
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
        
        [self setDestinationVC:indexPath destination:destination];
    }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView
                              indexPathForRowAtPoint:location];
    
    ZBPackageTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    previewingContext.sourceRect = cell.frame;
    
    ZBPackageDepictionViewController *packageDepictionVC = (ZBPackageDepictionViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
    
    
    [self setDestinationVC:indexPath destination:packageDepictionVC];
    
    return packageDepictionVC;
    
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

- (void)databaseCompletedUpdate {
    [self refreshTable];
}

- (void)darkMode:(NSNotification *)notif {
    [self.tableView reloadData];
    self.tableView.sectionIndexColor = [UIColor tintColor];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
}

@end
