//
//  ZBSearchViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/27/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <ZBDevice.h>
#import "ZBSearchViewController.h"
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import <Database/ZBDatabaseManager.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActionsManager.h>
#import <UIColor+GlobalColors.h>
#import <Packages/Views/ZBPackageTableViewCell.h>

@interface ZBSearchViewController () {
    ZBDatabaseManager *databaseManager;
    NSArray *results;
    BOOL searching;
    id<UIViewControllerPreviewing> previewing;
    NSMutableArray *searches;
}
@end

@implementation ZBSearchViewController

@synthesize searchController;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    searches = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"searches"] mutableCopy];
    if (!searches) {
        searches = [NSMutableArray new];
    }
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
    if ([ZBDevice darkModeEnabled]) {
        searchController.searchBar.keyboardAppearance = UIKeyboardAppearanceDark;
    }
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
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil]
         forCellReuseIdentifier:@"packageTableViewCell"];
    
    previewing = [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
    [self refreshTable];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
}

- (void)refreshTable {
    [UIView transitionWithView: self.tableView
                      duration: 0.35f
                      options: UIViewAnimationOptionTransitionCrossDissolve
                      animations: ^(void) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.tableView reloadData];
                            [self setNeedsStatusBarAppearanceUpdate];
                        });
                      }completion: nil];
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
    }
    else {
        results = nil;
    }
    [self refreshTable];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [databaseManager closeDatabase];
    results = [databaseManager searchForPackageName:[searchBar text] numberOfResults:-1];
    [self refreshTable];
    if ([searches containsObject:searchBar.text]) {
        [searches removeObject:searchBar.text];
    }
    [searches insertObject:searchBar.text atIndex:0];
    NSLog(@"[Zebra] Searches: %@", searches);
    [[NSUserDefaults standardUserDefaults] setObject:searches forKey:@"searches"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [databaseManager openDatabase];
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    results = nil;
    [self refreshTable];
    [databaseManager closeDatabase];
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
}

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    [self unregisterForPreviewingWithContext:previewing];
    previewing = [searchController registerForPreviewingWithDelegate:self sourceView:self.tableView];
    [self refreshTable];
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    [searchController unregisterForPreviewingWithContext:previewing];
    previewing = [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    results = nil;
    [self refreshTable];
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
    if (!searchController.active) {
        return [searches count];
    } else {
        return results.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searchController.active) {
        ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
        ZBPackage *package = [results objectAtIndex:indexPath.row];
        [cell updateData:package];
        cell.packageLabel.textColor = [UIColor cellPrimaryTextColor];
        cell.descriptionLabel.textColor = [UIColor cellSecondaryTextColor];
        cell.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
        return cell;
    } else {
        static NSString *recentSearches = @"recentSearches";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:recentSearches];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:recentSearches];
        }
        cell.textLabel.text = [searches objectAtIndex:indexPath.row];
        cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
        cell.backgroundColor = [UIColor selectedCellBackgroundColor:NO];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searchController.active) {
        [self performSegueWithIdentifier:@"segueSearchToPackageDepiction" sender:indexPath];
    } else {
        searchController.active = YES;
        searchController.searchBar.text = [searches objectAtIndex:indexPath.row];
        [self searchBar:searchController.searchBar textDidChange:[searches objectAtIndex:indexPath.row]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 10;
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

- (void)darkMode:(NSNotification *)notif {
    [self refreshTable];
    self.tableView.sectionIndexColor = [UIColor tintColor];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
    searchController.searchBar.tintColor = [UIColor tintColor];
    searchController.searchBar.keyboardAppearance = [[notif name] isEqualToString:@"darkMode"] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceDefault;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([ZBDevice darkModeEnabled]) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

- (void)dealloc {
    [databaseManager closeDatabase];
}

@end
