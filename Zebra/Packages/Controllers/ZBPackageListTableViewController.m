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

@interface ZBPackageListTableViewController () {
    ZBDatabaseManager *databaseManager;
    NSArray *packages;
    int numberOfPackages;
    BOOL needsExpansion;
    BOOL needsSecondSection;
    NSArray *updates;
}
@end

@implementation ZBPackageListTableViewController

@synthesize repoID;
@synthesize section;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (repoID == 0) {
        [self queueButton];
        [self upgradeButton];
        [self refreshTable];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    needsExpansion = false;
    databaseManager = [[ZBDatabaseManager alloc] init];
    if (repoID == 0) {
        [self queueButton];
        [self upgradeButton];
        [self refreshTable];
    }
    else {
        packages = [databaseManager packagesFromRepo:repoID inSection:section numberOfPackages:100 startingAt:0];
        numberOfPackages = (int)packages.count;
    }
}

- (void)refreshTable {
    packages = [databaseManager installedPackages];
    numberOfPackages = (int)packages.count;
        
    ZBTabBarController *tabController = (ZBTabBarController *)self.tabBarController;
    needsSecondSection = [tabController hasUpdates];
    
    if (needsSecondSection) {
        updates = [tabController updates];
    }
        
    [self.tableView reloadData];
}

- (void)loadNextPackages {
    int before = numberOfPackages;
    NSArray *nextPackages = [databaseManager packagesFromRepo:repoID inSection:section numberOfPackages:100 startingAt:numberOfPackages];
    packages = [packages arrayByAddingObjectsFromArray:nextPackages];
    numberOfPackages = (int)packages.count;
    
    if (numberOfPackages > [self.tableView numberOfRowsInSection:0]) {
        needsExpansion = true;
        NSMutableArray *indexArray = [NSMutableArray new];
        for (int i = 0; i < numberOfPackages - before; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [indexArray addObject:indexPath];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        });
    }
}

- (void)upgradeButton {
    if (needsSecondSection) {
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
    if (needsSecondSection) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (needsSecondSection && section == 0) {
        return updates.count;
    }
    else {
        if (needsExpansion) {
            return numberOfPackages;
        }
        else if ([databaseManager numberOfPackagesInRepo:repoID] > 1000) {
            return 1000;
        }
        else if ([databaseManager numberOfPackagesInRepo:repoID] > 500) {
            return 500;
        }
        else {
            return [databaseManager numberOfPackagesInRepo:repoID];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
    
    if (needsSecondSection &&  indexPath.section == 0) {
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
        
//        if (error != nil) {
//            NSLog(@"[Zebra] %@", error);
//        }
    }
    else {
        ZBPackage *package = (ZBPackage *)[packages objectAtIndex:indexPath.row];
        
        cell.textLabel.text = package.name;
        cell.detailTextLabel.text = package.desc;
        
        if ((indexPath.row == numberOfPackages - 25) && (repoID != 0)) {
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
        
//        if (error != nil) {
//            NSLog(@"[Zebra] %@", error);
//        }
    }
    
    CGSize itemSize = CGSizeMake(35, 35);
    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
    [cell.imageView.image drawInRect:imageRect];
    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ZBPackage *package;
    
    if (needsSecondSection && indexPath.section == 0) {
        package = [updates objectAtIndex:indexPath.row];
    }
    else {
        package = [packages objectAtIndex:indexPath.row];
    }
    
    ZBPackageDepictionViewController *depictionController = [[ZBPackageDepictionViewController alloc] initWithPackage:package];
    [[self navigationController] pushViewController:depictionController animated:true];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (repoID == 0 && needsSecondSection && section == 0) {
        return @"Available Upgrades";
    }
    
    if (needsSecondSection) {
        return @"Installed Packages";
    }
    
    return @"";
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
