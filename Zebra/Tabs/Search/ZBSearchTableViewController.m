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

@interface ZBSearchTableViewController () {
    ZBDatabaseManager *databaseManager;
    NSArray *recentSearches;
}
@end

@implementation ZBSearchTableViewController

@synthesize searchController;

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    recentSearches = [[NSUserDefaults standardUserDefaults] arrayForKey:@"recentSearches"];
    if (!recentSearches) {
        recentSearches = [NSArray new];
    }
    
    if (!databaseManager) {
        databaseManager = [ZBDatabaseManager sharedInstance];
    }
    
    if (!searchController) {
        searchController = [[UISearchController alloc] initWithSearchResultsController:[[ZBSearchResultsTableViewController alloc] init]];
        searchController.delegate = self;
        searchController.searchBar.delegate = self;
        searchController.searchBar.tintColor = [UIColor accentColor];
        searchController.searchBar.placeholder = NSLocalizedString(@"Tweaks, Themes, and More", @"");
    }
    
    if (@available(iOS 9.1, *)) {
        searchController.obscuresBackgroundDuringPresentation = NO;
    }
    
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
}

#pragma mark - Helper Methods

- (void)clearSearches {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"searches"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    recentSearches = [NSArray new];
    [self.tableView reloadData];
}

#pragma mark - Search Controller Delegate

#pragma mark - Search Bar Delegate

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return recentSearches.count > 0 ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return recentSearches.count;
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
    [titleLabel setTextColor:[UIColor accentColor]];
    
    titleLabel.font = [UIFont systemFontOfSize:19.0 weight:UIFontWeightBold];
    [headerView addSubview:titleLabel];
    
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [clearButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [clearButton setTitle:@"Clear" forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearSearches) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:clearButton];
    
    NSDictionary *views = @{@"left": @10, @"title": titleLabel, @"button": clearButton};
    NSDictionary *metrics = @{@"left": [NSNumber numberWithFloat:self.tableView.separatorInset.left]};
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[title]-[button]-left-|" options:0 metrics:metrics views:views]];
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[title]-0-|" options:0 metrics:nil views:views]];
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[button]-0-|" options:0 metrics:nil views:views]];
 
    return headerView;
}

@end
