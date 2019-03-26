//
//  ZBSearchViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/27/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBSearchViewController.h"
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import <Database/ZBDatabaseManager.h>
#import <Packages/Helpers/ZBPackage.h>

@interface ZBSearchViewController () {
    ZBDatabaseManager *databaseManager;
    NSArray *results;
}
@end

@implementation ZBSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    databaseManager = [[ZBDatabaseManager alloc] init];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    [self.searchController.searchBar sizeToFit];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (![searchText isEqualToString:@""]) {
        results = [databaseManager searchForPackageName:searchText numberOfResults:25];
        [self.tableView reloadData];
    }
    else {
        results = nil;
        [self.tableView reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    results = [databaseManager searchForPackageName:[searchBar text] numberOfResults:-1];
    [self.tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchPackageTableViewCell" forIndexPath:indexPath];
    
    ZBPackage *package = (ZBPackage *)[results objectAtIndex:indexPath.row];
    
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
    
    ZBPackage *package = [results objectAtIndex:indexPath.row];
    ZBPackageDepictionViewController *depictionController = [[ZBPackageDepictionViewController alloc] initWithPackage:package];
    [[self navigationController] pushViewController:depictionController animated:true];
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
    // Return NO if you do not want the item tao be re-orderable.
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
