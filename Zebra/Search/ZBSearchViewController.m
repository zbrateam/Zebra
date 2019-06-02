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
#import <Packages/Helpers/ZBPackageActionsManager.h>
#import <UIColor+GlobalColors.h>
#import <Packages/Helpers/ZBPackageTableViewCell.h>

@interface ZBSearchViewController () {
    ZBDatabaseManager *databaseManager;
    NSArray *results;
    BOOL searching;
    id<UIViewControllerPreviewing> previewing;
}
@end

@implementation ZBSearchViewController

@synthesize searchController;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!databaseManager) {
        databaseManager = [ZBDatabaseManager sharedInstance];
    }
    
    if (!searchController) {
        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    }
    
    searchController.delegate = self;
    searchController.searchBar.delegate = self;
    searchController.searchBar.tintColor = [UIColor tintColor];
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
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil]
         forCellReuseIdentifier:@"packageTableViewCell"];
    
    previewing = [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
}

- (void)handleURL:(NSURL *_Nullable)url {
    if (url == NULL) {
        if (!searchController) {
            searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        }
        
        [searchController.searchBar becomeFirstResponder];
    }
    else {
        NSArray *path = [url pathComponents];
        if ([path count] == 2) {
            if (!databaseManager) {
                databaseManager = [ZBDatabaseManager sharedInstance];
            }
            
            if (!searchController) {
                searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
            }
            
            NSString *searchTerm = path[1];
            [(UITextField *)[self.searchController.searchBar valueForKey:@"searchField"] setText:searchTerm];
            [self searchBarSearchButtonClicked:self.searchController.searchBar];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (![searchText isEqualToString:@""]) {
        results = [databaseManager searchForPackageName:searchText numberOfResults:25];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
    else {
        results = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [databaseManager closeDatabase];
    results = [databaseManager searchForPackageName:[searchBar text] numberOfResults:-1];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [databaseManager openDatabase];
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [databaseManager closeDatabase];
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
}

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    [self unregisterForPreviewingWithContext:previewing];
    previewing = [searchController registerForPreviewingWithDelegate:self sourceView:self.tableView];
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    [searchController unregisterForPreviewingWithContext:previewing];
    previewing = [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    results = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ((results == nil) || (results.count)) {
        tableView.backgroundView = nil;
        return 1;
    }
    else {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, tableView.bounds.size.height)];
        label.text = @"No Results Found";
        label.textColor = [UIColor cellSecondaryTextColor];
        label.textAlignment = NSTextAlignmentCenter;
        tableView.backgroundView = label;
        return 0;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];

    ZBPackage *package = [results objectAtIndex:indexPath.row];
    
    [cell updateData:package];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"segueSearchToPackageDepiction" sender:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 10;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 5;
}

#pragma mark - Swipe actions

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = (ZBPackage *)[results objectAtIndex:indexPath.row];
    return [ZBPackageActionsManager rowActionsForPackage:package indexPath:indexPath viewController:self parent:nil completion:^(void) {
        [tableView reloadData];
    }];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView setEditing:NO animated:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
    NSIndexPath *indexPath = sender;
    
    destination.package = [results objectAtIndex:indexPath.row];
    
    [databaseManager closeDatabase];
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView
                              indexPathForRowAtPoint:location];
    
    ZBPackageTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    previewingContext.sourceRect = cell.frame;
    
    ZBPackageDepictionViewController *packageDepictionVC = (ZBPackageDepictionViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
    
    packageDepictionVC.package = [results objectAtIndex:indexPath.row];

    return packageDepictionVC;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

- (void)dealloc {
    [databaseManager closeDatabase];
}

@end
