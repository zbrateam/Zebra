//
//  AUPMPackageListViewController.m
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "AUPMPackageListViewController.h"
#import "AUPMRepo.h"
#import "AUPMPackage.h"
#import "AUPMDatabaseManager.h"
#import "AUPMQueue.h"
#import "AUPMAppDelegate.h"
#import "AUPMPackageViewController.h"
#import "AUPMQueueViewController.h"

@interface AUPMPackageListViewController () {
    NSArray *_updateObjects;
    BOOL _hasUpdates;
    RLMResults<AUPMPackage *> *_objects;
    AUPMRepo *_repo;
}

@end

@implementation AUPMPackageListViewController

- (id)initWithRepo:(AUPMRepo *)repo {
    self = [super init];
    if (self) {
        _repo = repo;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_repo != NULL) {
        _objects = [[_repo packages] sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"packageName" ascending:YES]]];
        
        self.title = [_repo repoName];
    }
    else {
        [self refreshTable];
        
        self.title = @"Packages";
    }
}

- (void)refreshTable {
    AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
    _hasUpdates = [databaseManager hasPackagesThatNeedUpdates];
    _updateObjects = [databaseManager updateObjects];
    AUPMQueue *queue = [AUPMQueue sharedInstance];

    if ([queue hasObjects]) {
        UIBarButtonItem *queueItem = [[UIBarButtonItem alloc] initWithTitle:@"Queue" style:UIBarButtonItemStylePlain target:self action:@selector(viewQueue)];
        self.navigationItem.leftBarButtonItem = queueItem;
    }
    else {
        self.navigationItem.leftBarButtonItems = nil;
    }
    
    if (_hasUpdates) {
        UIBarButtonItem *upgradeItem = [[UIBarButtonItem alloc] initWithTitle:@"Upgrade All" style:UIBarButtonItemStyleDone target:self action:@selector(upgradeAllPackages)];
        self.navigationItem.rightBarButtonItem = upgradeItem;
    }
    else {
        self.navigationItem.rightBarButtonItems = nil;
    }
    
    _objects = [[AUPMPackage objectsWhere:@"installed = true"] sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"packageName" ascending:YES]]];
    
    [self.tableView reloadData];
}

- (void)viewQueue {
    AUPMQueueViewController *queueVC = [[AUPMQueueViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:queueVC];
    [self presentViewController:navController animated:true completion:nil];
}

- (void)upgradeAllPackages {
    AUPMQueue *queue = [AUPMQueue sharedInstance];

    [queue addPackages:_updateObjects toQueueWithAction:AUPMQueueActionUpgrade];

    AUPMQueueViewController *queueVC = [[AUPMQueueViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:queueVC];
    [self presentViewController:navController animated:true completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_hasUpdates) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_hasUpdates && section == 0) {
        return [_updateObjects count];
    }
    else {
        return [_objects count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_hasUpdates && section == 0) {
        return @"Updates";
    }
    else if (section == 1) {
        return @"Installed Packages";
    }
    else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"PackageTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    AUPMPackage *package;
    
    if (_hasUpdates && indexPath.section == 0) {
        package = _updateObjects[indexPath.row];
    }
    else {
        package = _objects[indexPath.row];
    }
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    NSString *section = [[package section] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    if ([section characterAtIndex:[section length] - 1] == ')') {
        NSArray *items = [section componentsSeparatedByString:@"("]; //Remove () from section
        section = [items[0] substringToIndex:[items[0] length] - 1];
    }
    NSString *iconPath = [NSString stringWithFormat:@"/Applications/Cydia.app/Sections/%@.png", section];
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:iconPath options:0 error:&error];
    UIImage *sectionImage = [UIImage imageWithData:data];
    if (sectionImage != NULL) {
        cell.imageView.image = sectionImage;
    }
    else if (_repo != NULL) {
        cell.imageView.image = [UIImage imageWithData:[_repo icon]];
    }

    if ([package tags] != NULL && [[package tags] rangeOfString:@"cydia::commercial"].location != NSNotFound) {
        cell.textLabel.textColor = [UIColor colorWithRed:0.62 green:0.67 blue:0.90 alpha:1.0];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.62 green:0.67 blue:0.90 alpha:1.0];
    }
    else {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }
    
    cell.textLabel.text = [package packageName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", [package packageIdentifier], [package version]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    CGSize itemSize = CGSizeMake(35, 35);
    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
    [cell.imageView.image drawInRect:imageRect];
    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AUPMPackage *package;
    if (_hasUpdates && indexPath.section == 0) {
        package = _updateObjects[indexPath.row];
        AUPMPackageViewController *packageVC = [[AUPMPackageViewController alloc] initWithPackage:package];
        [self.navigationController pushViewController:packageVC animated:YES];
    }
    else {
        package = _objects[indexPath.row];
        AUPMPackageViewController *packageVC = [[AUPMPackageViewController alloc] initWithPackage:package];
        [self.navigationController pushViewController:packageVC animated:YES];
    }
}

@end
