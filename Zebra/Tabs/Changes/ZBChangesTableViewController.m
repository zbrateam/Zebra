//
//  ZBChangesTableViewController.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 2/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBChangesTableViewController.h"

#import <ZBLog.h>
#import <ZBAppDelegate.h>
#import <ZBSettings.h>
#import <ZBDevice.h>
#import <Tabs/Packages/Helpers/ZBPackagePartitioner.h>
#import <Managers/ZBPackageManager.h>
#import <Model/ZBPackage.h>
#import <Tabs/Packages/Helpers/ZBPackageActions.h>
#import <UI/Packages/Views/Cells/ZBPackageTableViewCell.h>
#import <Tabs/Packages/Controllers/ZBPackageViewController.h>
#import <ZBDevice.h>
#import <Extensions/UIColor+GlobalColors.h>
#import <Tabs/ZBTabBarController.h>
#import <Model/ZBSource.h>

@import SDWebImage;
@import FirebaseAnalytics;

@interface ZBChangesTableViewController () {
    ZBPackageManager *packageManager;
    NSUserDefaults *defaults;
    NSArray *packages;
    NSArray *availableOptions;
    NSMutableArray *sectionIndexTitles;
    int totalNumberOfPackages;
    int numberOfPackages;
    int databaseRow;
}
@property (nonatomic, weak) ZBPackageViewController *previewPackageDepictionVC;
@property (nonatomic, weak) SFSafariViewController *previewSafariVC;
@end

@implementation ZBChangesTableViewController

- (BOOL)useBatchLoad {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    packageManager = [ZBPackageManager sharedInstance];
    [self applyLocalization];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureTheme) name:@"darkMode" object:nil];
    self.tableView.contentInset = UIEdgeInsetsMake(5, 0, 0, 0);
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
    defaults = [NSUserDefaults standardUserDefaults];
    [self refreshTable];
}

- (void)applyLocalization {
    // This isn't exactly "best practice", but this way the text in IB isn't useless.
    self.navigationItem.title = NSLocalizedString([self.navigationItem.title capitalizedString], @"");
}

- (void)configureTheme {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
        self.tableView.sectionIndexColor = [UIColor accentColor];
        [self.navigationController.navigationBar setTintColor:[UIColor accentColor]];
        self.tableView.tableHeaderView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBDatabaseCompletedUpdate" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"darkMode" object:nil];
}

- (void)updateSections {
    self.tableData = [self partitionObjects:packages collationStringSelector:@selector(lastSeen)];
}

- (void)refreshTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->packages = [self->packageManager latestPackages:100];
        self->databaseRow = self.batchLoadCount - 1;
        self->numberOfPackages = (int)[self->packages count];
        self.batchLoad = YES;
        self.continueBatchLoad = self.batchLoad;
        [self updateSections];
        [self.tableView reloadData];
    });
}

- (void)loadNextPackages {
//    if (!self.continueBatchLoad || self.isPerformingBatchLoad) {
//        return;
//    }
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (self->databaseRow < self->totalNumberOfPackages) {
//            self.isPerformingBatchLoad = YES;
//            NSArray *nextPackages = [self->databaseManager packagesFromSource:NULL inSection:NULL numberOfPackages:self.batchLoadCount startingAt:self->databaseRow enableFiltering:YES];
//            if (nextPackages.count == 0) {
//                self.continueBatchLoad = self.isPerformingBatchLoad = NO;
//                return;
//            }
//            self->packages = [self->packages arrayByAddingObjectsFromArray:nextPackages];
//            self->numberOfPackages = (int)[self->packages count];
//            self->databaseRow += self.batchLoadCount;
//            [self updateSections];
//            [self.tableView reloadData];
//            self.isPerformingBatchLoad = NO;
//        }
//    });
}

#pragma mark - Table view data source

- (NSArray <ZBPackage *> *)objectAtSection:(NSInteger)section {
    if ([self.tableData count] == 0)
        return nil;
    return [self.tableData objectAtIndex:section];
}

- (ZBPackage *)packageAtIndexPath:(NSIndexPath *)indexPath {
    return [self objectAtSection:indexPath.section][indexPath.row];
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
        return [ZBPackagePartitioner titleForHeaderInDateSection:section sectionIndexTitles:sectionIndexTitles dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
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
    ZBPackage *package = [self packageAtIndexPath:indexPath];
//    ZBPackage *candidate = [package installableCandidate];
    if (package) {
        ZBPackageViewController *packageDepiction = [[ZBPackageViewController alloc] initWithPackage:package];
        
        [[self navigationController] pushViewController:packageDepiction animated:YES];
    }
}

#pragma mark - Swipe actions

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = [self packageAtIndexPath:indexPath];
    return [ZBPackageActions swipeActionsForPackage:package inTableView:tableView];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView setEditing:NO animated:YES];
}

- (void)scrollToTop {
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

@end
