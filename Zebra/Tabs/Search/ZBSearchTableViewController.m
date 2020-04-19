//
//  ZBSearchTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSearchTableViewController.h"

#import <Database/ZBDatabaseManager.h>
#import <Search/ZBSearchResultsTableViewController.h>

#import <Extensions/UIColor+GlobalColors.h>

#define MAX_SEARCH_RECENT_COUNT 5

@interface ZBSearchTableViewController () {
    ZBDatabaseManager *databaseManager;
    NSMutableArray *recentSearches;
    
    BOOL shouldPerformSearching;
    BOOL liveSearch;
}
@end

@implementation ZBSearchTableViewController

@synthesize searchController;

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    }
    else {
        self.tableView.tableHeaderView = searchController.searchBar;
    }
    
    self.title = NSLocalizedString(@"Search", @"");
    self.definesPresentationContext = YES;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self tableView] setBackgroundColor:[UIColor groupedTableViewBackgroundColor]];
}

- (void)setupView {
    recentSearches = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"recentSearches"] mutableCopy];
    if (!recentSearches) {
        recentSearches = [NSMutableArray new];
    }
    
    if (!databaseManager) {
        databaseManager = [ZBDatabaseManager sharedInstance];
    }
    
    if (!searchController) {
        searchController = [[UISearchController alloc] initWithSearchResultsController:[[ZBSearchResultsTableViewController alloc] initWithNavigationController:self.navigationController]];
        searchController.delegate = self;
        searchController.searchResultsUpdater = self;
        searchController.searchBar.delegate = self;
        searchController.searchBar.tintColor = [UIColor accentColor];
        searchController.searchBar.placeholder = NSLocalizedString(@"Tweaks, Themes, and More", @"");
        searchController.searchBar.scopeButtonTitles = @[NSLocalizedString(@"Name", @""), NSLocalizedString(@"Description", @""), NSLocalizedString(@"Author", @"")];
    }
    
    if (@available(iOS 9.1, *)) {
        searchController.obscuresBackgroundDuringPresentation = NO;
    }
}

#pragma mark - Helper Methods

- (void)clearSearches {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"recentSearches"];
    
    [recentSearches removeAllObjects];
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
}

#pragma mark - Search Results Updating Protocol

- (void)updateSearchResultsForSearchController:(nonnull UISearchController *)searchController {
    ZBSearchResultsTableViewController *resultsController = (ZBSearchResultsTableViewController *)searchController.searchResultsController;
    [resultsController setLive:self->liveSearch];
    
    NSArray *results = nil;
    
    if (self->shouldPerformSearching) {
        NSString *strippedString = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([strippedString length] <= 1) {
            results = @[];
            
            [resultsController setFilteredResults:results];
            [resultsController refreshTable];
            return;
        }
        
        NSUInteger selectedIndex = searchController.searchBar.selectedScopeButtonIndex;
        switch (selectedIndex) {
            case 0:
                results = [databaseManager searchForPackageName:strippedString fullSearch:!self->liveSearch];
                break;
            case 1:
                results = [databaseManager packagesWithDescription:strippedString fullSearch:!self->liveSearch];
                break;
            case 2:
                results = [databaseManager packagesByAuthorName:strippedString email:NULL fullSearch:!self->liveSearch];
                break;
        }
    }
    
    [resultsController setFilteredResults:results];
    [resultsController refreshTable];
}

#pragma mark - Search Controller Delegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    self->liveSearch = [ZBSettings wantsLiveSearch];
    self->shouldPerformSearching = self->liveSearch;
}

#pragma mark - Search Bar Delegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self->liveSearch = [ZBSettings wantsLiveSearch];
    self->shouldPerformSearching = self->liveSearch;
    
    [self updateSearchResultsForSearchController:searchController];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    
    self->shouldPerformSearching = YES;
    self->liveSearch = NO;
    
    NSString *newSearch = searchBar.text;
    if (![recentSearches containsObject:newSearch]) {
        if ([recentSearches count] >= MAX_SEARCH_RECENT_COUNT) {
            [recentSearches removeObjectAtIndex:MAX_SEARCH_RECENT_COUNT - 1];
        }
        [recentSearches insertObject:newSearch atIndex:0];
        [[NSUserDefaults standardUserDefaults] setObject:recentSearches forKey:@"recentSearches"];
    }
    
    [self updateSearchResultsForSearchController:searchController];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self updateSearchResultsForSearchController:searchController];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    searchController.searchBar.text = recentSearches[indexPath.row];
    searchController.active = YES;
    [[self searchController].searchBar becomeFirstResponder];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return recentSearches.count ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MIN(recentSearches.count, MAX_SEARCH_RECENT_COUNT);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"recentSearchCell" forIndexPath:indexPath];
    
    cell.textLabel.text = recentSearches[indexPath.row];
    cell.textLabel.textColor = [UIColor accentColor];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return recentSearches.count ? NSLocalizedString(@"Recent", @"") : NULL;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height)];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    [titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [titleLabel setText:[self tableView:tableView titleForHeaderInSection:section]];
    [titleLabel setTextColor:[UIColor primaryTextColor]];
    
    titleLabel.font = [UIFont systemFontOfSize:19.0 weight:UIFontWeightBold];
    [headerView addSubview:titleLabel];
    
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [clearButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [clearButton setTitle:NSLocalizedString(@"Clear", @"") forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearSearches) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:clearButton];
    
    NSDictionary *views = @{@"left": @10, @"title": titleLabel, @"button": clearButton};
    NSDictionary *metrics = @{@"left": [NSNumber numberWithFloat:self.tableView.separatorInset.left]};
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[title]-[button]-left-|" options:0 metrics:metrics views:views]];
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[title]-0-|" options:0 metrics:nil views:views]];
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[button]-0-|" options:0 metrics:nil views:views]];
 
    return headerView;
}

#pragma mark - URL Handling

- (void)handleURL:(NSURL *_Nullable)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (url == NULL) {
            [self setupView];
            
            [self->searchController.searchBar becomeFirstResponder];
        } else {
            NSArray *path = [url pathComponents];
            if ([path count] == 2) {
                [self setupView];
                
                NSString *searchTerm = path[1];
                [self->searchController.searchBar becomeFirstResponder];
                [(UITextField *)[self.searchController.searchBar valueForKey:@"searchField"] setText:searchTerm];
            }
        }
    });
}

- (void)scrollToTop {
    if (searchController.searchResultsController) {
        [searchController.searchResultsController performSelector:@selector(scrollToTop)];
    }
    else {
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    }
}

@end
