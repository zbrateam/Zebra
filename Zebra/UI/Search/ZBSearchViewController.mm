//
//  ZBSearchViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSearchViewController.h"

//#import "ZBPackageManager.h"

#import "ZBBoldTableViewHeaderView.h"
#import "ZBPackageTableViewCell.h"

#import "Zebra-Swift.h"
#import "ZBPackageActions.h"
#import "ZBPackageViewController.h"

#import <Plains/Plains.h>

@interface ZBSearchViewController () {
    NSMutableArray *recentSearches;
    NSArray *searchResults;
    UISearchController *searchController;
    UIActivityIndicatorView *spinner;
    BOOL isUpdatingResults;
}
@end

@implementation ZBSearchViewController

#pragma mark - Initializers

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self.title = NSLocalizedString(@"Search", @"");
        self.definesPresentationContext = YES;
        
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        self.tableView.tableFooterView = [[UIView alloc] init];
        [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"noResultsCell"];
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"recentSearchCell"];
        [self.tableView registerNib:[UINib nibWithNibName:@"ZBBoldTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"BoldTableViewHeaderView"];
        
        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.delegate = self;
        searchController.searchResultsUpdater = self;
        searchController.searchBar.delegate = self;
        searchController.searchBar.tintColor = [UIColor accentColor];
        searchController.searchBar.placeholder = NSLocalizedString(@"Tweaks, Themes, and More", @"");
        searchController.searchBar.scopeButtonTitles = @[NSLocalizedString(@"Name", @""), NSLocalizedString(@"Description", @""), NSLocalizedString(@"Author", @"")];
        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchController.obscuresBackgroundDuringPresentation = NO;
        
        self.navigationItem.searchController = searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        
        recentSearches = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"recentSearches"] mutableCopy];
        if (!recentSearches) {
            recentSearches = [NSMutableArray new];
        }
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:@"ZBPackageStatusUpdate" object:nil];
}

- (void)showSpinner {
    if (!spinner) {
        if (@available(iOS 13.0, *)) {
            spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        } else {
            spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        }
        spinner.hidesWhenStopped = YES;
        
        self.tableView.backgroundView = spinner;
    }
    
    [spinner startAnimating];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (void)hideSpinner {
    [spinner stopAnimating];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
}

#pragma mark - Helper Methods

- (void)clearSearches {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"recentSearches"];
    
    [recentSearches removeAllObjects];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Search Results Updating Protocol

- (void)reloadTable {
    [self.tableView reloadData];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *strippedString = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
    void (^updateTable)(NSArray *) = ^void(NSArray *packages) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->spinner.isAnimating) [self hideSpinner];
            if (self->isUpdatingResults) return;
            self->isUpdatingResults = YES;
            self->searchResults = packages;
            
            if (packages.count == 0 && strippedString.length != 0) {
                self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            } else {
                self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
            }
            
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            self->isUpdatingResults = NO;
        });
    };
    
    if (strippedString.length == 0) {
        updateTable(@[]);
        return;
    }
    
    NSUInteger selectedIndex = searchController.searchBar.selectedScopeButtonIndex;
    if (searchResults.count == 0) [self showSpinner]; // Only show the spinner if this is the initial search
    switch (selectedIndex) {
        case 0: {
            [[PLPackageManager sharedInstance] searchForPackagesWithName:strippedString completion:^(NSArray<PLPackage *> * _Nonnull packages) {
                updateTable(packages);
            }];
            break;
        }
        case 1: {
            [[PLPackageManager sharedInstance] searchForPackagesWithDescription:strippedString completion:^(NSArray<PLPackage *> * _Nonnull packages) {
                updateTable(packages);
            }];
            break;
        }
        case 2: {
            [[PLPackageManager sharedInstance] searchForPackagesWithAuthorName:strippedString completion:^(NSArray<PLPackage *> * _Nonnull packages) {
                updateTable(packages);
            }];
            break;
        }
    }
}

#pragma mark - Search Bar Delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *strippedString = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (strippedString.length > 0 && ![recentSearches containsObject:strippedString]) {
        [recentSearches insertObject:strippedString atIndex:0];
        if (recentSearches.count > 20) {
            [recentSearches removeLastObject];
        }
        [[NSUserDefaults standardUserDefaults] setObject:recentSearches forKey:@"recentSearches"];
    }
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (searchController.active && searchController.searchBar.text.length > 0) {
        return MAX(searchResults.count, 1); // Show 1 cell for the "no results" cell
    } else {
        return MIN(recentSearches.count, 5); // Show at most 5 "recent searches"
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searchController.active && searchController.searchBar.text.length > 0) {
        if (searchResults.count > 0) { // Show package cell
            return [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell"];
        } else { // Show no results cell
            return [tableView dequeueReusableCellWithIdentifier:@"noResultsCell"];
        }
    } else { // Show recent search cell
        return [tableView dequeueReusableCellWithIdentifier:@"recentSearchCell"];
    }
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searchController.active && searchController.searchBar.text.length > 0) {
        if (searchResults.count > 0) {
            ((ZBPackageTableViewCell *)cell).showAuthor = YES;
            ((ZBPackageTableViewCell *)cell).showSource = YES;
            
            [(ZBPackageTableViewCell *)cell setPackage:searchResults[indexPath.row]];
        } else {
            cell.textLabel.text = NSLocalizedString(@"No Results", @"");
            cell.textLabel.textColor = [UIColor secondaryLabelColor];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.font = [UIFont systemFontOfSize:15.0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    } else { // Show recent packages cell
        cell.textLabel.text = recentSearches[indexPath.row];
        cell.textLabel.textColor = [UIColor accentColor];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self->isUpdatingResults = NO;
    if (searchController.active && searchResults.count) {
        ZBPackageViewController *packageController = [[ZBPackageViewController alloc] initWithPackage:searchResults[indexPath.row]];
        [self.navigationController pushViewController:packageController animated:YES];
    } else if (!searchController.active && recentSearches.count) {
        searchController.searchBar.text = recentSearches[indexPath.row];
        searchController.active = YES;
        [self searchBarSearchButtonClicked:searchController.searchBar];
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searchController.active && searchResults.count) {
        return [ZBPackageActions swipeActionsForPackage:searchResults[indexPath.row] inTableView:self.tableView];
    } else {
        UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:NSLocalizedString(@"Remove", @"") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {

            if (self->recentSearches.count == 1) {
                [self clearSearches];
            } else {
                [self->recentSearches removeObjectAtIndex:indexPath.row];
                [[NSUserDefaults standardUserDefaults] setObject:self->recentSearches forKey:@"recentSearches"];

                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }

            completionHandler(YES);
        }];
        
        if ([ZBSettings swipeActionStyle] == ZBSwipeActionStyleIcon) {
            action.image = [UIImage imageNamed:@"delete_left"]; // This probably won't do anything due to the height of the cell
        }

        return [UISwipeActionsConfiguration configurationWithActions:@[action]];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (searchController.searchBar.text.length == 0 && recentSearches.count) {
        ZBBoldTableViewHeaderView *cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"BoldTableViewHeaderView"];
        cell.titleLabel.text = NSLocalizedString(@"Recent", @"");
        cell.actionButton.hidden = NO;
        [cell.actionButton setTitle:NSLocalizedString(@"Clear", @"") forState:UIControlStateNormal];
        [cell.actionButton addTarget:self action:@selector(clearSearches) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    
    return NULL;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    return searchController.searchBar.text.length == 0 && recentSearches.count ? 50 : 0;
}

#pragma mark - URL Handling

- (void)handleURL:(NSURL *_Nullable)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (url == nil) {
            [self->searchController.searchBar becomeFirstResponder];
        } else {
            NSArray *path = [url pathComponents];
            if (path.count == 2) {
                NSString *searchTerm = path[1];
                [self->searchController.searchBar becomeFirstResponder];
                [(UITextField *)[self->searchController.searchBar valueForKey:@"searchField"] setText:searchTerm];
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
