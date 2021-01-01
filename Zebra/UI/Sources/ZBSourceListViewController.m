//
//  ZBSourceListViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/1/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBSourceListViewController.h"

#import <Managers/ZBSourceManager.h>
#import <Model/ZBSource.h>
#import <Model/ZBSourceFilter.h>
#import <UI/Common/ZBPartialPresentationController.h>
#import <UI/Sources/Views/Cells/ZBSourceTableViewCell.h>
#import <UI/Sources/ZBSourceViewController.h>
#import <UI/Sources/ZBSourceFilterViewController.h>

@interface ZBSourceListViewController () {
    ZBSourceManager *sourceManager;
    UISearchController *searchController;
    UIActivityIndicatorView *spinner;
    NSArray <ZBSource *> *filterResults;
    NSArray *problems;
}
@property (nonnull) ZBSourceFilter *filter;
@end

@implementation ZBSourceListViewController

#pragma mark - Initializers

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self.title = NSLocalizedString(@"Sources", @"");
        
        sourceManager = [ZBSourceManager sharedInstance];
        
        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.obscuresBackgroundDuringPresentation = NO;
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchController.searchBar.showsBookmarkButton = YES;
        searchController.searchBar.delegate = self;
        if (@available(iOS 13.0, *)) {
            [searchController.searchBar setImage:[UIImage systemImageNamed:@"line.horizontal.3.decrease.circle"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
        } else {
            [searchController.searchBar setImage:[UIImage imageNamed:@"Unknown"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
        }
        
        self.navigationItem.searchController = searchController;
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedSourceRefresh) name:ZBFinishedSourceRefreshNotification object:NULL];
        
        self.filter = [[ZBSourceFilter alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithSources:(NSArray<ZBSource *> *)sources {
    self = [self init];
    
    if (self) {
        self.sources = sources;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshSources) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"problemTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBSourceTableViewCell" bundle:nil] forCellReuseIdentifier:@"sourceTableViewCell"];
    
    [self.tableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    
    [self loadSources];
}

- (void)loadSources {
    if (!self.isViewLoaded) return;
    
    if (_sources) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSArray <ZBSource *> *filteredSources = [self->sourceManager filterSources:self->_sources withFilter:self.filter];
            dispatch_async(dispatch_get_main_queue(), ^{
                self->filterResults = filteredSources;
                [UIView transitionWithView:self.tableView duration:0.20f options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void) {
                    if (@available(iOS 13.0, *)) {
                        if (self.filter.isActive) {
                            [self->searchController.searchBar setImage:[UIImage systemImageNamed:@"line.horizontal.3.decrease.circle.fill"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
                        } else {
                            [self->searchController.searchBar setImage:[UIImage systemImageNamed:@"line.horizontal.3.decrease.circle"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
                        }
                    }
                    [self.tableView reloadData];
                } completion:nil];
            });
        });
    } else { // Load sources for the first time, every other access is done by the filter and delegate methods
        self.sources = [sourceManager sources];
        [self loadSources];
    }
}

- (void)refreshSources {
    [sourceManager refreshSourcesUsingCaching:YES userRequested:YES error:nil];
}

#pragma mark - Filter Delegate

- (void)applyFilter:(ZBSourceFilter *)filter {
    self.filter = filter;

    [self loadSources];
//    [ZBSettings setFilter:self.filter forSource:self.source section:self.section];
}

#pragma mark - Search Results Updating Protocol

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchTerm = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    self.filter.searchTerm = searchTerm.length > 0 ? searchTerm : NULL;
    [self loadSources];
}

#pragma mark - Search Bar Delegate

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    ZBSourceFilterViewController *filter = [[ZBSourceFilterViewController alloc] initWithFilter:self.filter delegate:self];

    UINavigationController *filterVC = [[UINavigationController alloc] initWithRootViewController:filter];
    filterVC.modalPresentationStyle = UIModalPresentationCustom;
    filterVC.transitioningDelegate = self;

    [self presentViewController:filterVC animated:YES completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return problems.count ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (problems.count && section == 0) {
        return 1;
    } else {
        return filterResults.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (problems.count && indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"problemTableViewCell"];
        return cell;
    } else {
        ZBSourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceTableViewCell"];
        return cell;
    }
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (problems.count && indexPath.section == 0) {
        cell.textLabel.text = @"I got 99 problems and they're all dependencies.";
    } else {
        ZBSource *source = filterResults[indexPath.row];
        ZBSourceTableViewCell *sourceCell = (ZBSourceTableViewCell *)cell;
        [sourceCell setSource:source];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (problems.count && indexPath.section == 0) {
        
    } else {
        ZBSource *source = filterResults[indexPath.row];
        ZBSourceViewController *sourceViewController = [[ZBSourceViewController alloc] initWithSource:source editOnly:NO];
        
        [self.navigationController pushViewController:sourceViewController animated:YES];
    }
}

//- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
//    ZBPackage *package = updates.count && indexPath.section == 0 ? updates[indexPath.row] : filterResults[indexPath.row];
//    return [ZBPackageActions swipeActionsForPackage:package inTableView:tableView];
//}

#pragma mark - Presentation Controller

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    return [[ZBPartialPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting scale:0.35];
}

#pragma mark - Source Delegate

//- (void)finishedSourceRefresh {
//    _packages = NULL;
//    updates = NULL;
//
//    [self loadPackages];
//}

@end
