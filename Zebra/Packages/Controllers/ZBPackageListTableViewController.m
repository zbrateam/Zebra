//
//  ZBPackageListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBPackageListTableViewController.h"
#import "ZBDatabaseManager.h"

@interface ZBPackageListTableViewController () {
    ZBDatabaseManager *databaseManager;
    NSArray *packages;
    int numberOfPackages;
}
@end

@implementation ZBPackageListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    databaseManager = [[ZBDatabaseManager alloc] init];
    if (_repoID == 0) {
        packages = [databaseManager installedPackages];
        numberOfPackages = (int)packages.count;
    }
    else {
        packages = [databaseManager packagesFromRepo:_repoID numberOfPackages:100 startingAt:0];
        numberOfPackages = (int)packages.count;
        NSLog(@"Done %d", numberOfPackages);
    }
}

- (void)loadNextPackages {
    NSLog(@"Loading next packages! start %d, going %d", numberOfPackages, numberOfPackages + 100);
    NSArray *nextPackages = [databaseManager packagesFromRepo:_repoID numberOfPackages:100 startingAt:numberOfPackages];
    packages = [packages arrayByAddingObjectsFromArray:nextPackages];
    numberOfPackages = (int)packages.count;
    NSLog(@"Done %d", numberOfPackages);
    
    NSMutableArray *indexArray = [NSMutableArray new];
    for (int i = numberOfPackages - 100; i < numberOfPackages; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [indexArray addObject:indexPath];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return numberOfPackages;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
    
    NSDictionary *package = [packages objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [package objectForKey:@"name"];
    cell.detailTextLabel.text = [package objectForKey:@"id"];
    
    if (indexPath.row == numberOfPackages - 50) {
        [self loadNextPackages];
    }
    
    return cell;
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//
//    NSDictionary *package = [packages objectAtIndex:indexPath.row];
//    NSLog(@"Package: %@", package);
//}


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
