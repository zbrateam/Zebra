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
    UISearchController *searchController;
    BOOL searching;
}
@end

@implementation ZBSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    databaseManager = [[ZBDatabaseManager alloc] init];
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    
    searchController.searchBar.delegate = self;
    searchController.searchBar.tintColor = [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
    searchController.searchBar.placeholder = @"Packages";
    self.definesPresentationContext = YES;
    if (@available(iOS 9.1, *)) {
        searchController.obscuresBackgroundDuringPresentation = false;
    }
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = false;
    } else {
        self.tableView.tableHeaderView = searchController.searchBar;
    }
    self.tableView.tableFooterView = [UIView new];
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
    
    if ([package isPaid]) {
        cell.textLabel.textColor = [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.40 green:0.50 blue:0.98 alpha:1.0];
    }
    else {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
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

@end
