//
//  ZBChangesTableViewController.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 2/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBChangesTableViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActionsManager.h>
#import <Packages/Helpers/ZBPackageTableViewCell.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import <UIColor+GlobalColors.h>
#import "ZBAppDelegate.h"

@interface ZBChangesTableViewController () {
    NSArray *packages;
    NSArray *sectionIndexTitles;
    int totalNumberOfPackages;
    int numberOfPackages;
    int databaseRow;
}
@end

@implementation ZBChangesTableViewController

@synthesize databaseManager;

- (id)init {
    self = [super init];
    
    if (self) {
        if (!databaseManager) {
            databaseManager = [ZBDatabaseManager sharedInstance];
        }
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        if (!databaseManager) {
            databaseManager = [ZBDatabaseManager sharedInstance];
        }
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

- (void)updateSections {
    self.tableData = [self partitionObjects:packages collationStringSelector:@selector(lastSeenDate)];
}

- (void)refreshTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.batchLoadCount = 500;
        self->packages = [self->databaseManager packagesFromRepo:NULL inSection:NULL numberOfPackages:[self useBatchLoad] ? self.batchLoadCount : -1 startingAt:0];
        self->databaseRow = self.batchLoadCount - 1;
        self->totalNumberOfPackages = [self->databaseManager numberOfPackagesInRepo:NULL section:NULL];
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
            NSArray *nextPackages = [self->databaseManager packagesFromRepo:NULL inSection:NULL numberOfPackages:self.batchLoadCount startingAt:self->databaseRow];
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
    NSArray *sectionDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    for (NSDate *date in sectionIndexTitles) {
        [sections addObject:[partitions[date] sortedArrayUsingDescriptors:sectionDescriptors]];
    }
    return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [sectionIndexTitles objectAtIndex:section];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"seguePackagesToPackageDepiction" sender:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    BOOL hasDataInSection = [[self objectAtSection:section] count];
    if (hasDataInSection) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0)];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 10, 18)];
        [label setFont:[UIFont boldSystemFontOfSize:15]];
        [label setText:[NSDateFormatter localizedStringFromDate:sectionIndexTitles[section] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle]];
        
        if ([self.defaults boolForKey:@"darkMode"]) {
            [label setTextColor: [UIColor whiteColor]];
        } else {
            [label setTextColor: [UIColor cellPrimaryTextColor]];
        }
        [view addSubview:label];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[label]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-5-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
        return view;
    }
    else {
        return nil;
    }
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

-(void)darkMode:(NSNotification *)notif{
    [self.tableView reloadData];
    self.tableView.sectionIndexColor = [UIColor tintColor];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
}

@end
