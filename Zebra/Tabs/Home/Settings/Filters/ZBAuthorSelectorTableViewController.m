//
//  ZBAuthorSelectorTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBAuthorSelectorTableViewController.h"

#import <ZBSettings.h>
#import <Database/ZBDatabaseManager.h>
#import <Extensions/UIImageView+Zebra.h>
#import <Extensions/UIColor+GlobalColors.h>

@interface ZBAuthorSelectorTableViewController () {
    ZBDatabaseManager *databaseManager;
    NSArray *authors;
    NSString *selectedAuthor;
    BOOL shouldPerformSearching;
}
@end

@implementation ZBAuthorSelectorTableViewController

@synthesize searchController;

#pragma mark - View Controller Lifecycle

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        authors = @[];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
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
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    }
    
//    [[self tableView] setBackgroundColor:[UIColor groupedTableViewBackgroundColor]];
}

- (void)setupView {
    if (!databaseManager) {
        databaseManager = [ZBDatabaseManager sharedInstance];
    }
    
    if (!searchController) {
        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.delegate = self;
        searchController.searchResultsUpdater = self;
        searchController.searchBar.delegate = self;
        searchController.searchBar.tintColor = [UIColor accentColor];
        searchController.searchBar.placeholder = NSLocalizedString(@"Search for an Author", @"");
    }
    
    if (@available(iOS 9.1, *)) {
        searchController.obscuresBackgroundDuringPresentation = NO;
    }
    
    [self layoutNaviationButtons];
}

#pragma mark - Bar Button Actions

- (void)layoutNaviationButtons {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
}

- (void)addAuthors {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.authorsSelected(@[self->selectedAuthor]);
    });
    
    if (searchController.active) {
        [self goodbye]; // Have to dismiss twice
    }
    
    [self goodbye];
}

- (void)goodbye {
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Search Results Updating Protocol

- (void)updateSearchResultsForSearchController:(nonnull UISearchController *)searchController {
    
    if (self->shouldPerformSearching) {
        NSString *strippedString = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([strippedString length] <= 1) {
            return;
        }
        
        authors = [databaseManager searchForAuthor:strippedString fullSearch:!self->shouldPerformSearching];
    }
    
    [self refreshTable];
}

#pragma mark - Search Controller Delegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    self->shouldPerformSearching = [ZBSettings liveSearch];
}

#pragma mark - Search Bar Delegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self->shouldPerformSearching = [ZBSettings liveSearch];
    
    [self updateSearchResultsForSearchController:searchController];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    
    self->shouldPerformSearching = YES;
    
    [self updateSearchResultsForSearchController:searchController];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self updateSearchResultsForSearchController:searchController];
}

#pragma mark - Table View Data Source

- (void)refreshTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView transitionWithView:self.tableView
          duration:0.35f
          options:UIViewAnimationOptionTransitionCrossDissolve
          animations:^(void) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self setNeedsStatusBarAppearanceUpdate];
            });
          } completion:nil];
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [authors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sectionSelectorCell"];
    
    NSString *author = authors[indexPath.row];
    cell.textLabel.text = author;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    selectedAuthor = authors[indexPath.row];
    
    [self addAuthors];
}

@end
