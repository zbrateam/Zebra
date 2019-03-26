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
#import <Queue/ZBQueue.h>
#import <ZBTabBarController.h>
#import <Repos/Helpers/ZBRepo.h>

@interface ZBPackageListTableViewController () {
    ZBDatabaseManager *databaseManager;
    NSArray *packages;
    NSArray *updates;
    BOOL needsUpdatesSection;
    int totalNumberOfPackages;
    int numberOfPackages;
    int databaseRow;
}
@end

@implementation ZBPackageListTableViewController

@synthesize repo;
@synthesize section;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([repo repoID] == 0) {
        [self queueButton];
        [self upgradeButton];
        [self refreshTable];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    databaseManager = [[ZBDatabaseManager alloc] init];
    if ([repo repoID] == 0) {
        [self queueButton];
        [self upgradeButton];
        [self refreshTable];
    }
    else {
        packages = [databaseManager packagesFromRepo:repo inSection:section numberOfPackages:100 startingAt:0];
        databaseRow = 99;
        numberOfPackages = (int)[packages count];
        if (section != NULL) {
            totalNumberOfPackages = [databaseManager numberOfPackagesFromRepo:repo inSection:section];
        }
        else {
            totalNumberOfPackages = [databaseManager numberOfPackagesInRepo:repo];
        }
    }
}

- (void)refreshTable {
    packages = [databaseManager installedPackages];
    numberOfPackages = (int)[packages count];
        
    ZBTabBarController *tabController = (ZBTabBarController *)self.tabBarController;
    needsUpdatesSection = [tabController hasUpdates];
    
    if (needsUpdatesSection) {
        updates = [tabController updates];
    }
        
    [self.tableView reloadData];
}

- (void)loadNextPackages {
    if (databaseRow + 200 <= totalNumberOfPackages) {
        NSArray *nextPackages = [databaseManager packagesFromRepo:repo inSection:section numberOfPackages:200 startingAt:databaseRow];
        packages = [packages arrayByAddingObjectsFromArray:nextPackages];
        numberOfPackages = (int)[packages count];
        databaseRow += 199;
    }
    else if (totalNumberOfPackages - (databaseRow + 200) != 0) {
        NSArray *nextPackages = [databaseManager packagesFromRepo:repo inSection:section numberOfPackages:totalNumberOfPackages - (databaseRow + 200) startingAt:databaseRow];
        packages = [packages arrayByAddingObjectsFromArray:nextPackages];
        numberOfPackages = (int)[packages count];
        databaseRow += 199;
    }
}

- (void)upgradeButton {
    if (needsUpdatesSection) {
        UIBarButtonItem *updateButton = [[UIBarButtonItem alloc] initWithTitle:@"Upgrade All" style:UIBarButtonItemStylePlain target:self action:@selector(upgradeAll)];
        self.navigationItem.rightBarButtonItem = updateButton;
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)queueButton {
    if ([[ZBQueue sharedInstance] hasObjects]) {
        UIBarButtonItem *queueButton = [[UIBarButtonItem alloc] initWithTitle:@"Queue" style:UIBarButtonItemStylePlain target:self action:@selector(presentQueue)];
        self.navigationItem.leftBarButtonItem = queueButton;
    }
    else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)presentQueue {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"queueController"];
    [self presentViewController:vc animated:true completion:nil];
}

- (void)upgradeAll {
    ZBQueue *queue = [ZBQueue sharedInstance];
    
    [queue addPackages:updates toQueue:ZBQueueTypeUpgrade];
    [self presentQueue];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (needsUpdatesSection) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (needsUpdatesSection && section == 0) {
        return updates.count;
    }
    else {
        if (self.section != NULL) {
            return [databaseManager numberOfPackagesFromRepo:repo inSection:self.section];
        }
        else {
            return [databaseManager numberOfPackagesInRepo:repo];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
    
    if (needsUpdatesSection &&  indexPath.section == 0) {
        ZBPackage *package = (ZBPackage *)[updates objectAtIndex:indexPath.row];
        
        cell.textLabel.text = package.name;
        cell.detailTextLabel.text = package.desc;
        
        NSString *section = [package.section stringByReplacingOccurrencesOfString:@" " withString:@"_"];
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
    }
    else {
        ZBPackage *package = (ZBPackage *)[packages objectAtIndex:indexPath.row];
        
        cell.textLabel.text = package.name;
        cell.detailTextLabel.text = package.desc;
        
        if ((indexPath.row > [packages count] - ([packages count] / 10)) && ([repo repoID] != 0)) {
            [self loadNextPackages];
        }
        
        NSString *section = [package.section stringByReplacingOccurrencesOfString:@" " withString:@"_"];
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
    }
    
    if (cell.imageView.image != NULL) {
        CGSize itemSize = CGSizeMake(35, 35);
        UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
        [cell.imageView.image drawInRect:imageRect];
        cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ZBPackage *package;
    
    if (needsUpdatesSection && indexPath.section == 0) {
        package = [updates objectAtIndex:indexPath.row];
    }
    else {
        package = [packages objectAtIndex:indexPath.row];
    }
    
    ZBPackageDepictionViewController *depictionController = [[ZBPackageDepictionViewController alloc] initWithPackage:package];
    [[self navigationController] pushViewController:depictionController animated:true];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([repo repoID] == 0 && needsUpdatesSection && section == 0) {
        return @"Available Upgrades";
    }
    
    if (needsUpdatesSection) {
        return @"Installed Packages";
    }
    
    return @"";
}

@end
