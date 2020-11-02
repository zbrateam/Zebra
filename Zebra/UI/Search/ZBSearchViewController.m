//
//  ZBSearchViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import LNPopupController;

#import "ZBSearchViewController.h"

#import <Managers/ZBPackageManager.h>

#import <UI/Packages/Views/Cells/ZBPackageTableViewCell.h>

#import <Extensions/UIColor+GlobalColors.h>
#import <Tabs/Packages/Controllers/ZBPackageViewController.h>

#define MAX_SEARCH_RECENT_COUNT 5

@interface ZBSearchViewController () {
    ZBPackageManager *packageManager;
    NSMutableArray *recentSearches;
    NSArray *searchResults;
    UISearchController *searchController;
    UIActivityIndicatorView *spinner;
}
@end

@implementation ZBSearchViewController

#pragma mark - Initializers

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self.title = NSLocalizedString(@"Search", @"");
        
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        self.tableView.tableFooterView = [[UIView alloc] init];
        [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
        
        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.delegate = self;
        searchController.searchResultsUpdater = self;
        searchController.searchBar.tintColor = [UIColor accentColor];
        searchController.searchBar.placeholder = NSLocalizedString(@"Tweaks, Themes, and More", @"");
        searchController.searchBar.scopeButtonTitles = @[NSLocalizedString(@"Name", @""), NSLocalizedString(@"Description", @""), NSLocalizedString(@"Author", @"")];
        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchController.obscuresBackgroundDuringPresentation = NO;
        self.navigationItem.searchController = searchController;
        
        recentSearches = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"recentSearches"] mutableCopy];
        if (!recentSearches) {
            recentSearches = [NSMutableArray new];
        }
        
        packageManager = [ZBPackageManager sharedInstance];
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)showSpinner {
    if (!spinner) {
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
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
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
}

#pragma mark - Search Results Updating Protocol

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *strippedString = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
    void (^updateTable)(NSArray *) = ^void(NSArray *packages) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->spinner.isAnimating) [self hideSpinner];
            self->searchResults = packages;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
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
            [packageManager searchForPackagesByName:strippedString completion:^(NSArray<ZBPackage *> * _Nonnull packages) {
                updateTable(packages);
            }];
            break;
        }
        case 1: {
            [packageManager searchForPackagesByDescription:strippedString completion:^(NSArray<ZBPackage *> * _Nonnull packages) {
                updateTable(packages);
            }];
            break;
        }
        case 2: {
            [packageManager searchForPackagesByAuthorWithName:strippedString completion:^(NSArray<ZBPackage *> * _Nonnull packages) {
                updateTable(packages);
            }];
            break;
        }
    }
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(ZBPackageTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell updateData:searchResults[indexPath.row]];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ZBPackageViewController *packageController = [[ZBPackageViewController alloc] initWithPackage:searchResults[indexPath.row]];
    [self.navigationController pushViewController:packageController animated:YES];
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    return recentSearches.count ? NSLocalizedString(@"Recent", @"") : nil;
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height)];
//
//    UILabel *titleLabel = [[UILabel alloc] init];
//    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
//    titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
//    titleLabel.textColor = [UIColor primaryTextColor];
//
//    titleLabel.font = [UIFont systemFontOfSize:19.0 weight:UIFontWeightBold];
//    [headerView addSubview:titleLabel];
//
//    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
//    clearButton.translatesAutoresizingMaskIntoConstraints = NO;
//    [clearButton setTitle:NSLocalizedString(@"Clear", @"") forState:UIControlStateNormal];
//    [clearButton addTarget:self action:@selector(clearSearches) forControlEvents:UIControlEventTouchUpInside];
//    [headerView addSubview:clearButton];
//
//    NSDictionary *views = @{@"left": @10, @"title": titleLabel, @"button": clearButton};
//    NSDictionary *metrics = @{@"left": [NSNumber numberWithFloat:self.tableView.separatorInset.left]};
//    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[title]-[button]-left-|" options:0 metrics:metrics views:views]];
//    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[title]-0-|" options:0 metrics:nil views:views]];
//    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[button]-0-|" options:0 metrics:nil views:views]];
//
//    return headerView;
//}
//
//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    return YES;
//}
//
//- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSString *title = [ZBDevice useIcon] ? @"╳" : NSLocalizedString(@"Remove", @"");
//
//    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:title handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
//
//        if (self->recentSearches.count == 1) {
//            [self->recentSearches removeAllObjects];
//            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"recentSearches"];
//
//            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
//        } else {
//            [self->recentSearches removeObjectAtIndex:indexPath.row];
//            [[NSUserDefaults standardUserDefaults] setObject:self->recentSearches forKey:@"recentSearches"];
//
//            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
//        }
//
//        completionHandler(YES);
//    }];
//
//    return [UISwipeActionsConfiguration configurationWithActions:@[action]];
//}
//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    [tableView setEditing:NO animated:YES];
//}

#pragma mark - URL Handling

- (void)handleURL:(NSURL *_Nullable)url {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (url == nil) {
//            [self->searchController.searchBar becomeFirstResponder];
//        } else {
//            NSArray *path = [url pathComponents];
//            if (path.count == 2) {
//                NSString *searchTerm = path[1];
//                [self->searchController.searchBar becomeFirstResponder];
//                [(UITextField *)[self.searchController.searchBar valueForKey:@"searchField"] setText:searchTerm];
//            }
//        }
//    });
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
