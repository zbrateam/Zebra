//
//  ZBPackageListViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBPackageListViewController.h"
#import "ZBPackageFilterViewController.h"

#import <Model/ZBPackageFilter.h>
#import <UI/Packages/ZBPackageViewController.h>
#import <Tabs/Packages/Helpers/ZBPackageActions.h>
#if TARGET_OS_MACCATALYST
#import <UI/ZBSidebarController.h>
#endif
#import <UI/Common/Views/ZBBoldTableViewHeaderView.h>
#import <UI/Common/ZBPartialPresentationController.h>
#import <UI/Packages/Views/Cells/ZBPackageTableViewCell.h>
#import <ZBSettings.h>

#import <Extensions/UIViewController+Extensions.h>

#import <Plains/Plains.h>

@interface ZBPackageListViewController () {
//    ZBPackageManager *packageManager;
//    UISearchController *searchController;
    UIActivityIndicatorView *spinner;
    NSArray <PLPackage *> *filterResults;
    PLPackageManager *database;
}
//@property (nonnull) ZBPackageFilter *filter;
@end

@implementation ZBPackageListViewController

#pragma mark - Initializers

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self.title = @"Installed";
        
        database = [PLPackageManager sharedInstance];
        
//        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
//        searchController.obscuresBackgroundDuringPresentation = NO;
//        searchController.searchResultsUpdater = self;
//        searchController.delegate = self;
//        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
//        searchController.searchBar.showsBookmarkButton = YES;
//        searchController.searchBar.delegate = self;
//        if (@available(iOS 13.0, *)) {
//            [searchController.searchBar setImage:[UIImage systemImageNamed:@"line.horizontal.3.decrease.circle"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
//        } else {
//            [searchController.searchBar setImage:[UIImage imageNamed:@"Unknown"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
//        }
//
//        self.navigationItem.searchController = searchController;
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedSourceRefresh) name:ZBFinishedSourceRefreshNotification object:NULL];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedSourceRefresh) name:@"ZBPackageStatusUpdate" object:nil];
    }
    
    return self;
}

//- (void)dealloc {
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}
//
- (instancetype)initWithSource:(PLSource *)source {
    return [self initWithSource:source section:NULL];
}

- (instancetype)initWithSource:(PLSource *)source section:(NSString *_Nullable)section {
    self = [self init];

    if (self) {
        self.source = source;
        self.section = section;

        if (self.section) {
            self.title = NSLocalizedString(self.section, @"");
        } else {
            self.title = NSLocalizedString(@"All Packages", @"");
        }
    }

    return self;
}

- (instancetype)initWithPackages:(NSArray <PLPackage *> *)packages {
    self = [self init];

    if (self) {
        self.packages = packages;
    }

    return self;
}

//- (instancetype)initWithPackageIdentifiers:(NSArray<NSString *> *)identifiers {
//    self = [self init];
//
//    if (self) {
//        packageManager = [ZBPackageManager sharedInstance];
//
//        self.identifiers = identifiers;
//
//        self.filter = [[ZBPackageFilter alloc] init];
//    }
//
//    return self;
//}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBBoldTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"BoldTableViewHeaderView"];

    [self.tableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    
//    if (self.source && !self.source.remote) {
//        if (@available(iOS 13.0, *)) {
//            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"star"] style:UIBarButtonItemStylePlain target:self action:@selector(showFavorites)];
//        } else {
//            // FIXME: Fallback on earlier versions
//        }
//    } else if (self.isModal) {
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
//    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self loadPackages];
}

- (void)loadPackages {
    NSLog(@"[Zebra] Loading Packages");
    if (!self.isViewLoaded) return;
    
    [self showSpinner];
    if (_packages && _packages.count) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
//            NSArray <ZBPackage *> *filteredPackages = [self->packageManager filterPackages:self->_packages withFilter:self.filter];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideSpinner];
                self->filterResults = self->_packages;
                [UIView transitionWithView:self.tableView duration:0.20f options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void) {
//                    if (@available(iOS 13.0, *)) {
//                        if (self.filter.isActive) {
//                            [self->searchController.searchBar setImage:[UIImage systemImageNamed:@"line.horizontal.3.decrease.circle.fill"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
//                        } else {
//                            [self->searchController.searchBar setImage:[UIImage systemImageNamed:@"line.horizontal.3.decrease.circle"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
//                        }
//                    }
                    [self.tableView reloadData];
                } completion:nil];
            });
        });
    } else if (self.identifiers && self.identifiers.count) { // Load packages from identifiers
//        [packageManager fetchPackagesFromIdentifiers:self.identifiers completion:^(NSArray<ZBPackage *> * _Nonnull packages) {
//            self.packages = packages;
//            [self loadPackages];
//        }];
    } else { // Load packages for the first time, every other access is done by filter
        if (self.source) {
            if (self.section && ![self.section isEqualToString:@""]) {
                [database fetchPackagesMatchingFilter:^BOOL(PLPackage * _Nonnull package) {
                    return package.source == self.source && package.section == self.section;
                } completion:^(NSArray<PLPackage *> * _Nonnull packages) {
                    self.packages = packages;
                    [self loadPackages];
                }];
            } else {
                [database fetchPackagesMatchingFilter:^BOOL(PLPackage * _Nonnull package) {
                    return package.source == self.source;
                } completion:^(NSArray<PLPackage *> * _Nonnull packages) {
                    self.packages = packages;
                    [self loadPackages];
                }];
            }
        } else {
            [database fetchPackagesMatchingFilter:^BOOL(PLPackage * _Nonnull package) {
                return package.installed;
            } completion:^(NSArray<PLPackage *> * _Nonnull packages) {
                self.packages = packages;
                self.updates = self->database.updates;
                [self loadPackages];
            }];
        }
    }
}

- (void)showSpinner {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self->spinner) {
            if (@available(iOS 13.0, macCatalyst 13.0, *)) {
                self->spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
            } else {
                self->spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            }

            self->spinner.hidesWhenStopped = YES;
            
            self.tableView.backgroundView = self->spinner;
        }
        
        [self->spinner startAnimating];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    });
}

- (void)hideSpinner {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->spinner stopAnimating];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    });
}

- (void)updateAll {
    for (PLPackage *package in _updates) {
        [[PLQueue sharedInstance] addPackage:package toQueue:PLQueueUpgrade];
    }
}

- (void)showFavorites {
    NSArray <NSString *> *favorites = [ZBSettings favoritePackages];
    if (!favorites || !favorites.count) {
        UIAlertController *noFavorites = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No Favorites", @"") message:NSLocalizedString(@"There are no favorites to view.", @"") preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil];
        [noFavorites addAction:action];
        
        [self presentViewController:noFavorites animated:YES completion:nil];
        return;
    }
    
    ZBPackageListViewController *favoritesController = [[ZBPackageListViewController alloc] initWithPackageIdentifiers:favorites];
    favoritesController.title = NSLocalizedString(@"Favorites", @"");
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:favoritesController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Filter Delegate

- (void)applyFilter:(ZBPackageFilter *)filter {
//    self.filter = filter;
    
//    [self loadPackages];
//    if (self.filter.source) [ZBSettings setFilter:self.filter forSource:self.source section:self.section];
}

#pragma mark - Search Results Updating Protocol

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
//    NSString *searchTerm = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
//    self.filter.searchTerm = searchTerm.length > 0 ? searchTerm : NULL;
//    [self loadPackages];
}

#pragma mark - Search Bar Delegate

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
//    ZBPackageFilterViewController *filter = [[ZBPackageFilterViewController alloc] initWithFilter:self.filter delegate:self];
    
//    UINavigationController *filterVC = [[UINavigationController alloc] initWithRootViewController:filter];
//    filterVC.modalPresentationStyle = UIModalPresentationCustom;
//    filterVC.transitioningDelegate = self;
    
//    [self presentViewController:filterVC animated:YES completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _updates.count ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _updates.count && section == 0 ? _updates.count : filterResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell"];
    BOOL inUpdatesSection = _updates.count && indexPath.section == 0;
    if (inUpdatesSection) {
        cell.showSize = NO;
        cell.showVersion = YES;
    } else {
//        cell.showSize = _filter.sortOrder == ZBPackageSortOrderSize;
        cell.showVersion = NO;
    }
    
    PLPackage *package = _updates.count && indexPath.section == 0 ? _updates[indexPath.row] : filterResults[indexPath.row];
    [cell setPackage:package];
    
    return cell;
}

#pragma mark - Table View Delegate

//- (void)tableView:(UITableView *)tableView willDisplayCell:(ZBPackageTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    ZBPackage *package = updates.count && indexPath.section == 0 ? updates[indexPath.row] : filterResults[indexPath.row];
//    [cell updateData:package];
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PLPackage *package = _updates.count && indexPath.section == 0 ? _updates[indexPath.row] : filterResults[indexPath.row];
    ZBPackageViewController *packageVC = [[ZBPackageViewController alloc] initWithPackage:package];
    
    [self.navigationController pushViewController:packageVC animated:YES];
}

//- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
//    ZBPackage *package = updates.count && indexPath.section == 0 ? updates[indexPath.row] : filterResults[indexPath.row];
//    return [ZBPackageActions swipeActionsForPackage:package inTableView:tableView];
//}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (_updates.count) {
        ZBBoldTableViewHeaderView *cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"BoldTableViewHeaderView"];
        if (section == 0) {
            cell.actionButton.hidden = NO;
            [cell.actionButton setTitle:NSLocalizedString(@"Update All", @"") forState:UIControlStateNormal];
            [cell.actionButton addTarget:self action:@selector(updateAll) forControlEvents:UIControlEventTouchUpInside];
        } else {
            cell.actionButton.hidden = YES;
        }
        cell.titleLabel.text = section == 0 ? NSLocalizedString(@"Updates", @"") : NSLocalizedString(@"Installed", @"");
        return cell;
    }

    return NULL;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    return _updates.count ? 45 : 0;
}

#pragma mark - Presentation Controller

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    return [[ZBPartialPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting scale:0.52];
}

#pragma mark - Source Delegate

- (void)finishedSourceRefresh {
    _packages = NULL;
//    updates = NULL;
    
//    [self loadPackages];
}

@end
