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
    NSArray <NSArray <NSString *> *> *authors;
    NSMutableDictionary <NSString *, NSString *> *selectedAuthors;
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
        selectedAuthors = [[ZBSettings blockedAuthors] mutableCopy];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
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
        searchController.hidesNavigationBarDuringPresentation = NO;
    }
    
    if (@available(iOS 13.0, *)) {
        searchController.automaticallyShowsCancelButton = NO;
    }
    else {
        searchController.searchBar.showsCancelButton = NO;
    }
    
    
    if (@available(iOS 9.1, *)) {
        searchController.obscuresBackgroundDuringPresentation = NO;
    }
    
    [self layoutNaviationButtons];
}

#pragma mark - Bar Button Actions

- (void)layoutNaviationButtons {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", @"") style:UIBarButtonItemStyleDone target:self action:@selector(addAuthors)];
    self.navigationItem.rightBarButtonItem.enabled = [[selectedAuthors allKeys] count];
}

- (void)addAuthors {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.authorsSelected(self->selectedAuthors);
    });
    
    if (searchController.active) {
        [searchController setActive:NO];
    }
    
    [self goodbye];
}

- (void)goodbye {
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Search Results Updating Protocol

- (void)updateSearchResultsForSearchController:(nonnull UISearchController *)searchController {
    NSString *searchTerm = searchController.searchBar.text;
    if ([searchTerm length] <= 1) {
        authors = @[];
    }
    else if (self->shouldPerformSearching) {
        NSString *strippedString = [searchTerm stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([strippedString length] <= 1) {
            authors = @[];
            return;
        }
        
        authors = [databaseManager searchForAuthorName:strippedString fullSearch:!self->shouldPerformSearching];
    }
    
    [self refreshTable];
}

#pragma mark - Search Controller Delegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    self->shouldPerformSearching = [ZBSettings wantsLiveSearch];
}

#pragma mark - Search Bar Delegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self->shouldPerformSearching = [ZBSettings wantsLiveSearch];
    
    [self updateSearchResultsForSearchController:searchController];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    
    self->shouldPerformSearching = YES;
    
    [self updateSearchResultsForSearchController:searchController];
    [self.searchController setActive:false];
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
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"sectionSelectorCell"];
    
    NSArray *authorDetail = authors[indexPath.row];
    cell.textLabel.text = authorDetail[0];
    cell.textLabel.textColor = [UIColor primaryTextColor];
    
    cell.detailTextLabel.text = authorDetail[1];
    cell.detailTextLabel.textColor = [UIColor secondaryTextColor];

    cell.accessoryType = [[selectedAuthors allKeys] containsObject:authorDetail[1]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    NSArray *authorDetail = authors[indexPath.row];
    if ([selectedAuthors objectForKey:authorDetail[1]]) {
        [selectedAuthors removeObjectForKey:authorDetail[1]];
    }
    else {
        [selectedAuthors setObject:authorDetail[0] forKey:authorDetail[1]];
    }
    
    [[self tableView] reloadData];
    [self layoutNaviationButtons];
}

@end
