//
//  ZBAuthorSelectorTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBAuthorSelectorTableViewController.h"
#import "UITableView+Settings.h"
#import "ZBOptionSettingsTableViewCell.h"
#import "ZBOptionSubtitleSettingsTableViewCell.h"

#import <ZBSettings.h>
#import <Extensions/UIImageView+Zebra.h>
#import <Extensions/ZBColor.h>

@interface ZBAuthorSelectorTableViewController () {
    NSArray <NSArray <NSString *> *> *authors;
    NSMutableDictionary <NSString *, NSString *> *selectedAuthors;
    NSMutableArray *newSelectedAuthors;
}
@end

@implementation ZBAuthorSelectorTableViewController

@synthesize searchController;

#pragma mark - View Controller Lifecycle

- (id)init {
    self = [super init];
    
    if (self) {
        authors = @[];
        newSelectedAuthors = [NSMutableArray new];
        selectedAuthors = [[ZBSettings blockedAuthors] mutableCopy];
        newSelectedAuthors = [NSMutableArray new];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
    
    self.navigationItem.searchController = searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    self.title = NSLocalizedString(@"Search", @"");
    self.definesPresentationContext = YES;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    [self.tableView registerCellTypes:@[@(ZBOptionSettingsCell), @(ZBOptionSubtitleSettingsCell)]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [searchController setActive:YES];
}

- (void)setupView {    
    if (!searchController) {
        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.delegate = self;
        searchController.searchResultsUpdater = self;
        searchController.searchBar.delegate = self;
        searchController.searchBar.tintColor = [ZBColor accentColor];
        searchController.searchBar.placeholder = NSLocalizedString(@"Search for an Author", @"");
        searchController.hidesNavigationBarDuringPresentation = NO;
    }
    
    if (@available(iOS 13.0, *)) {
        searchController.automaticallyShowsCancelButton = NO;
    }
    else {
        searchController.searchBar.showsCancelButton = NO;
    }
    
    searchController.obscuresBackgroundDuringPresentation = NO;
    
    [self layoutNaviationButtons];
}

#pragma mark - Bar Button Actions

- (void)layoutNaviationButtons {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", @"") style:UIBarButtonItemStyleDone target:self action:@selector(addAuthors)];
    self.navigationItem.rightBarButtonItem.enabled = [newSelectedAuthors count];
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
    if (searchController.active) {
        [searchController setActive:NO];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Search Results Updating Protocol

- (void)updateSearchResultsForSearchController:(nonnull UISearchController *)searchController {
    NSString *searchTerm = searchController.searchBar.text;
    if (searchTerm.length <= 1) {
        authors = @[];
    }
    else {
        NSString *strippedString = [searchTerm stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (strippedString.length <= 1) {
            authors = @[];
            return;
        }
        
//        [databaseManager searchForAuthorsByNameOrEmail:strippedString completion:^(NSArray <NSArray <NSString *> *> *authors) {
//            self->authors = authors;
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self refreshTable];
//            });
//        }];
    }
}

#pragma mark - Search Controller Delegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [searchController.searchBar becomeFirstResponder];
    });
}

#pragma mark - Search Bar Delegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self refreshTable];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self updateSearchResultsForSearchController:searchController];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
        
    [self updateSearchResultsForSearchController:searchController];
}

#pragma mark - Table View Data Source

- (void)refreshTable {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return authors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray <NSString *> *authorDetail = authors[indexPath.row];
    ZBOptionSettingsTableViewCell *cell;
    
    if ([authorDetail[0] isEqualToString:authorDetail[1]]) {
        cell = [tableView dequeueOptionSettingsCellForIndexPath:indexPath];
        
        cell.textLabel.text = authorDetail[0] ?: authorDetail[1];
    } else {
        cell = [tableView dequeueOptionSubtitleSettingsCellForIndexPath:indexPath];
        
        cell.textLabel.text = authorDetail[0];
        cell.detailTextLabel.text = authorDetail[1];
    }
    
    [cell setChosen:authorDetail[1].length && [[selectedAuthors allKeys] containsObject:authorDetail[1]]];
    [cell applyStyling];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray <NSString *> *authorDetail = authors[indexPath.row];
    NSString *email = authorDetail[1];
    
    // TODO: How do we handle the packages that their author do not provide an email
    if (email.length == 0)
        return;
    
    // Assume the authors have their email
    if (selectedAuthors[email]) {
        [selectedAuthors removeObjectForKey:email];
        [newSelectedAuthors removeObject:email];
    }
    else if (email.length) {
        [selectedAuthors setObject:authorDetail[0] forKey:email];
        [newSelectedAuthors addObject:email];
    }
    
//    [self chooseUnchooseOptionAtIndexPath:indexPath];
    [self layoutNaviationButtons];
}

@end
