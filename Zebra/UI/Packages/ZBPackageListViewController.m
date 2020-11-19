//
//  ZBPackageListViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBPackageListViewController.h"
#import "ZBPackageFilterViewController.h"

#import <Managers/ZBPackageManager.h>
#import <Model/ZBPackage.h>
#import <Model/ZBPackageFilter.h>
#import <Model/ZBSource.h>
#import <Tabs/Packages/Controllers/ZBPackageViewController.h>
#import <UI/Packages/Views/Cells/ZBPackageTableViewCell.h>
#import <UI/Common/ZBPartialPresentationController.h>

@interface ZBPackageListViewController () {
    ZBPackageManager *packageManager;
    UISearchController *searchController;
    UIActivityIndicatorView *spinner;
    NSArray *filterResults;
}
@property (nonnull) ZBPackageFilter *filter;
@end

@implementation ZBPackageListViewController

#pragma mark - Initializers

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.obscuresBackgroundDuringPresentation = NO;
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchController.searchBar.showsBookmarkButton = YES;
        searchController.searchBar.delegate = self;
        [searchController.searchBar setImage:[UIImage systemImageNamed:@"line.horizontal.3.decrease.circle"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
        
        self.navigationItem.searchController = searchController;
    }
    
    return self;
}

- (instancetype)initWithSource:(ZBSource *)source {
    return [self initWithSource:source section:NULL];
}

- (instancetype)initWithSource:(ZBSource *)source section:(NSString *_Nullable)section {
    self = [self init];
    
    if (self) {
        packageManager = [ZBPackageManager sharedInstance];
        
        self.source = source;
        self.section = [section isEqualToString:@"ALL_PACKAGES"] ? NULL : section;
        
        if (self.source.remote) {
            if (self.section) {
                self.title = NSLocalizedString(self.section, @"");
            } else {
                self.title = NSLocalizedString(@"All Packages", @"");
            }
        } else {
            self.title = NSLocalizedString(@"Installed", @"");
        }
        
        self.filter = [[ZBPackageFilter alloc] initWithSource:source section:section];
    }
    
    return self;
}

- (instancetype)initWithPackages:(NSArray <ZBPackage *> *)packages {
    self = [self init];
    
    if (self) {
        self.packages = packages;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];

    [self.tableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
        
    [self loadPackages];
}

- (void)loadPackages {
    [self showSpinner];
    if (_packages) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSArray *filteredPackages = [self->packageManager filterPackages:self.packages withFilter:self.filter];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideSpinner];
                self->filterResults = filteredPackages;
                [UIView transitionWithView:self.tableView duration:0.20f options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void) {
                    if (self.filter.isActive) {
                        [searchController.searchBar setImage:[UIImage systemImageNamed:@"line.horizontal.3.decrease.circle.fill"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
                    } else {
                        [searchController.searchBar setImage:[UIImage systemImageNamed:@"line.horizontal.3.decrease.circle"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
                    }
                    [self.tableView reloadData];
                } completion:nil];
            });
        });
    } else { // Load packages for the first time
        ZBPackageFilter *originalFilter = [[ZBPackageFilter alloc] initWithSource:self.source section:self.section];
        [packageManager packagesMatchingFilter:originalFilter completion:^(NSArray<ZBPackage *> * _Nonnull packages) {
            self.packages = packages;
            [self loadPackages];
        }];
    }
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

#pragma mark - Filter Delegate

- (void)applyFilter:(ZBPackageFilter *)filter {
    self.filter = filter;
    
    [self loadPackages];
}

#pragma mark - Search Results Updating Protocol

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchTerm = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    self.filter.searchTerm = searchTerm.length > 0 ? searchTerm : NULL;
    [self loadPackages];
}

#pragma mark - Search Bar Delegate

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    ZBPackageFilterViewController *filter = [[ZBPackageFilterViewController alloc] initWithFilter:self.filter delegate:self];
    
    UINavigationController *filterVC = [[UINavigationController alloc] initWithRootViewController:filter];
    filterVC.modalPresentationStyle = UIModalPresentationCustom;
    filterVC.transitioningDelegate = self;
    
    [self presentViewController:filterVC animated:YES completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1; // For now
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return filterResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell"];
    
    return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(ZBPackageTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell updateData:filterResults[indexPath.row] calculateSize:self.filter.sortOrder == ZBPackageSortOrderSize showVersion:NO];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ZBPackageViewController *packageVC = [[ZBPackageViewController alloc] initWithPackage:filterResults[indexPath.row]];
    [self.navigationController pushViewController:packageVC animated:YES];
}

#pragma mark - Presentation Controller

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    return [[ZBPartialPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting scale:0.52];
}

@end
