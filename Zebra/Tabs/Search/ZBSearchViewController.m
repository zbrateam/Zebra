//
//  ZBSearchViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/27/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <ZBDevice.h>
#import <ZBAppDelegate.h>
#import <ZBSettings.h>
#import "ZBSearchViewController.h"
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import <Database/ZBDatabaseManager.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActionsManager.h>
#import <Queue/ZBQueue.h>
#import <UIColor+GlobalColors.h>
#import <Packages/Views/ZBPackageTableViewCell.h>

@interface ZBSearchViewController () {
    ZBDatabaseManager *databaseManager;
    NSArray *results;
    BOOL searching;
    id <UIViewControllerPreviewing> previewing;
    NSMutableArray *recentSearches;
}
@end

enum ZBSearchSection {
    ZBSearchSectionNotFound,
    ZBSearchSectionRecent,
    ZBSearchSectionResults
};

@implementation ZBSearchViewController

@synthesize searchController;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    recentSearches = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"searches"] mutableCopy];
    if (!recentSearches) {
        recentSearches = [NSMutableArray new];
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
    
    self.definesPresentationContext = YES;
    if (@available(iOS 9.1, *)) {
        searchController.obscuresBackgroundDuringPresentation = NO;
    }
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
    } else {
        self.tableView.tableHeaderView = searchController.searchBar;
    }
    self.tableView.tableFooterView = [UIView new];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    
    previewing = [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
    [self configureClearSearchButton];
    [self refreshTable];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
}

- (void)configureClearSearchButton {
    self.navigationItem.rightBarButtonItem = recentSearches.count ? [[UIBarButtonItem alloc] initWithTitle:@"Clear Search" style:UIBarButtonItemStylePlain target:self action:@selector(clearSearches)] : nil;
}

- (void)clearSearches {
    [self->recentSearches removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"searches"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.navigationItem.rightBarButtonItem = nil;
    [self refreshTable];
}

- (void)refreshTable {
    [UIView transitionWithView:self.tableView
      duration:0.35f
      options:UIViewAnimationOptionTransitionCrossDissolve
      animations:^(void) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self setNeedsStatusBarAppearanceUpdate];
        });
      } completion:nil];
}

- (void)handleURL:(NSURL *_Nullable)url {
    if (url == NULL) {
        if (!searchController) {
            searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        }
        [searchController.searchBar becomeFirstResponder];
    } else {
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
    if (![[NSUserDefaults standardUserDefaults] boolForKey:liveSearchKey]) {
        return;
    }
    if (searchText.length) {
        results = [databaseManager searchForPackageName:searchText numberOfResults:60];
    } else {
        results = nil;
    }
    [self refreshTable];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    NSString *query = [searchBar text];
    if (query.length <= 1) {
        [ZBAppDelegate sendErrorToTabController:@"This search query is too short for the full search, please use a longer query."];
        return;
    }
    results = [databaseManager searchForPackageName:query numberOfResults:-1];
    [self refreshTable];
    if ([recentSearches containsObject:query]) {
        [recentSearches removeObject:query];
    }
    [recentSearches insertObject:query atIndex:0];
    NSLog(@"[Zebra] Searches: %@", recentSearches);
    [[NSUserDefaults standardUserDefaults] setObject:recentSearches forKey:@"searches"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self configureClearSearchButton];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    results = nil;
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    [self refreshTable];
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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case ZBSearchSectionNotFound:
            return results && results.count == 0 ? 1 : 0;
        case ZBSearchSectionRecent:
            return results.count || searchController.active ? 0 : recentSearches.count;
        case ZBSearchSectionResults:
            return results.count;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ZBSearchSectionNotFound: {
            static NSString *notFoundID = @"notFound";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:notFoundID];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:notFoundID];
            }
            cell.textLabel.text = @"No Results Found";
            cell.textLabel.textColor = [UIColor cellSecondaryTextColor];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            return cell;
        }
        case ZBSearchSectionRecent: {
            static NSString *recentSearchesID = @"recentSearches";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:recentSearchesID];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:recentSearchesID];
            }
            cell.textLabel.text = [recentSearches objectAtIndex:indexPath.row];
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            cell.backgroundColor = [UIColor selectedCellBackgroundColor:NO];
            return cell;
        }
        case ZBSearchSectionResults: {
            ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
            if (indexPath.row < results.count) {
                ZBPackage *package = [results objectAtIndex:indexPath.row];
                [cell updateData:package];
                [cell setColors];
            }
            return cell;
        }
        default:
            return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ZBSearchSectionRecent:
            searchController.active = YES;
            searchController.searchBar.text = [recentSearches objectAtIndex:indexPath.row];
            [self searchBarSearchButtonClicked:searchController.searchBar];
            break;
        case ZBSearchSectionResults:
            [self performSegueWithIdentifier:@"segueSearchToPackageDepiction" sender:indexPath];
            break;
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ZBSearchSectionNotFound: {
            if (results.count)
                return 0;
            break;
        }
        case ZBSearchSectionRecent: {
            if (searchController.active || results.count)
                return 0;
            break;
        }
        case ZBSearchSectionResults: {
            if (!results.count)
                return 0;
            break;
        }
    }
    return UITableViewAutomaticDimension;
}

#pragma mark - Swipe actions

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ZBSearchSectionResults: {
            ZBPackage *package = (ZBPackage *)[results objectAtIndex:indexPath.row];
            return [ZBPackageActionsManager rowActionsForPackage:package indexPath:indexPath viewController:self parent:nil completion:^(void) {
                [tableView reloadData];
            }];
        }
        case ZBSearchSectionRecent: {
            UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:[[ZBQueue sharedInstance] queueToKeyDisplayed:ZBQueueTypeRemove] handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                [self->recentSearches removeObjectAtIndex:indexPath.row];
                [[NSUserDefaults standardUserDefaults] setObject:self->recentSearches forKey:@"searches"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self configureClearSearchButton];
                [tableView beginUpdates];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [tableView endUpdates];
            }];
            deleteAction.backgroundColor = [UIColor redColor];
            return @[deleteAction];
        }
        default: {
            return nil;
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView setEditing:NO animated:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
    NSIndexPath *indexPath = sender;
    destination.package = [results objectAtIndex:indexPath.row];
    destination.view.backgroundColor = [UIColor tableViewBackgroundColor];
}

- (UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    if (indexPath.section != ZBSearchSectionResults) {
        return nil;
    }
    ZBPackageTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    previewingContext.sourceRect = cell.frame;
    ZBPackage *package = [results objectAtIndex:indexPath.row];
    ZBPackageDepictionViewController *packageDepictionVC = (ZBPackageDepictionViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
    packageDepictionVC.package = package;
    return packageDepictionVC;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    if (viewControllerToCommit == nil) {
        return;
    }
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

- (void)darkMode:(NSNotification *)notif {
    [self refreshTable];
    self.tableView.sectionIndexColor = [UIColor tintColor];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
    searchController.searchBar.tintColor = [UIColor tintColor];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [ZBDevice darkModeEnabled] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

@end
