//
//  ZBSourceListViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/1/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBSourceListViewController.h"

#import <Tabs/Sources/Controllers/ZBSourceAddViewController.h>

#import <Extensions/UIColor+GlobalColors.h>
#import <Managers/ZBSourceManager.h>
#import <Model/ZBSource.h>
#import <Model/ZBSourceFilter.h>
#import <UI/Common/ZBPartialPresentationController.h>
#import <UI/Sources/Views/Cells/ZBSourceTableViewCell.h>
#import <UI/Sources/ZBSourceViewController.h>
#import <UI/Sources/ZBSourceFilterViewController.h>
#import <ZBSettings.h>

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
        
        self.filter = [[ZBSourceFilter alloc] init];
        
        [self registerForNotifications];
    }
    
    return self;
}

- (void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startedSourceRefresh) name:ZBFinishedSourceRefreshNotification object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addedSources:) name:ZBAddedSourcesNotification object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removedSources:) name:ZBRemovedSourcesNotification object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startedDownloadingSource:) name:ZBStartedSourceDownloadNotification object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedImportingSource:) name:ZBFinishedSourceImportNotification object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedSourceRefresh) name:ZBFinishedSourceRefreshNotification object:NULL];
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
    if (sourceManager.refreshInProgress) [self.refreshControl beginRefreshing];
    
    [self layoutNavigationButtons];
    
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
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
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            self.sources = [self->sourceManager sources];
            [self loadSources];
        });
    }
}

- (void)refreshSources {
    [sourceManager refreshSourcesUsingCaching:YES userRequested:YES error:nil];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [self layoutNavigationButtons];
}

- (void)layoutNavigationButtons {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.editing) {
            self.navigationItem.leftBarButtonItem = self.editButtonItem;
            
            UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(exportSources)];
            UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteSources)];
            deleteButton.enabled = NO;
            
            self.navigationItem.rightBarButtonItems = @[shareButton, deleteButton];
        } else {
            self.navigationItem.leftBarButtonItem = self.editButtonItem;
            self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddSourceView)]];
        }
    });
}

- (void)exportSources {
    NSMutableArray *sourcesToExport = [NSMutableArray new];
    NSArray <NSIndexPath *> *selectedIndexes = [self.tableView indexPathsForSelectedRows];
    @synchronized (self) {
        if (selectedIndexes && selectedIndexes.count) {
            for (NSIndexPath *indexPath in selectedIndexes) {
                [sourcesToExport addObject:filterResults[indexPath.row]];
            }
        } else {
            [sourcesToExport addObjectsFromArray:filterResults];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:sourcesToExport applicationActivities:nil];
        shareSheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems[0];
                    
        [self presentViewController:shareSheet animated:YES completion:nil];
    });
}

- (void)deleteSources {
    NSMutableArray *sourcesToDelete = [NSMutableArray new];
    NSArray <NSIndexPath *> *selectedIndexes = [self.tableView indexPathsForSelectedRows];
    @synchronized (self) {
        if (selectedIndexes && selectedIndexes.count) {
            for (NSIndexPath *indexPath in selectedIndexes) {
                [sourcesToDelete addObject:filterResults[indexPath.row]];
            }
        } else {
            [sourcesToDelete addObjectsFromArray:filterResults];
        }
    }
    
    if (!sourcesToDelete.count) return;
    
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to remove %lu sources?", @""), (unsigned long)sourcesToDelete.count];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure?", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
        
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self->sourceManager removeSources:[NSSet setWithArray:sourcesToDelete] error:nil];
    }];
    [alert addAction:confirm];
        
    UIAlertAction *deny = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:deny];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)showAddSourceView {
    [self showAddSourceViewWithURL:NULL];
}

- (void)showAddSourceViewWithURL:(NSURL *)url {
    ZBSourceAddViewController *addView = [[ZBSourceAddViewController alloc] initWithURL:url];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addView];
    
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Filter Delegate

- (void)applyFilter:(ZBSourceFilter *)filter {
    self.filter = filter;

    [self loadSources];
    [ZBSettings setSourceFilter:self.filter];
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
        cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu sources could not be fetched.", @""), (unsigned long)problems.count];
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.textColor = [UIColor secondaryTextColor];
        cell.detailTextLabel.numberOfLines = 0;
        cell.tintColor = [UIColor systemPinkColor];
        if (@available(iOS 13.0, *)) { // TODO: Export SFSymbol
            cell.imageView.image = [UIImage systemImageNamed:@"exclamationmark.triangle.fill"];
        }
    } else {
        ZBSourceTableViewCell *sourceCell = (ZBSourceTableViewCell *)cell;
        ZBSource *source = filterResults[indexPath.row];
        [sourceCell setSource:source];
        [sourceCell setSpinning:source.busy];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        self.navigationItem.rightBarButtonItems[1].enabled = tableView.indexPathsForSelectedRows.count;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        self.navigationItem.rightBarButtonItems[1].enabled = tableView.indexPathsForSelectedRows.count;
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (problems.count && indexPath.section == 0) {
        
    } else {
        ZBSource *source = filterResults[indexPath.row];
        ZBSourceViewController *sourceViewController = [[ZBSourceViewController alloc] initWithSource:source editOnly:NO];
        
        [self.navigationController pushViewController:sourceViewController animated:YES];
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = filterResults[indexPath.row];
    
    NSMutableArray *actions = [NSMutableArray new];
    if ([source canDelete]) {
        UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:NSLocalizedString(@"Delete", @"") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            NSError *error = NULL;
            [self->sourceManager removeSources:[NSSet setWithArray:@[source]] error:&error];
            
            completionHandler(error == NULL);
        }];
        if ([ZBSettings swipeActionStyle] == ZBSwipeActionStyleIcon) {
            deleteAction.image = [UIImage imageNamed:@"delete_left"];
        }
        [actions addObject:deleteAction];
    }
    
    UIContextualAction *refreshAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:NSLocalizedString(@"Refresh", @"") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self->sourceManager refreshSources:@[source] useCaching:NO error:nil];
        completionHandler(YES);
    }];
    if ([ZBSettings swipeActionStyle] == ZBSwipeActionStyleIcon) {
        refreshAction.image = [UIImage imageNamed:@"arrow_clockwise"];
    }
    [actions addObject:refreshAction];
    
    return [UISwipeActionsConfiguration configurationWithActions:actions];
}

#pragma mark - Presentation Controller

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    return [[ZBPartialPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting scale:0.30];
}

#pragma mark - Source Delegate

- (void)startedSourceRefresh {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isViewLoaded) {
            [self.refreshControl beginRefreshing];
        }
    });
}

- (void)addedSources:(NSNotification *)notification {
    if (!self.isViewLoaded) return;

    NSSet *sourcesToAdd = notification.userInfo[@"sources"];
    if (!sourcesToAdd.count) return;

    @synchronized (self) {
        NSMutableArray *mutableSources = self->_sources.mutableCopy;
        [mutableSources addObjectsFromArray:sourcesToAdd.allObjects];
        self->_sources = mutableSources;
            
        self->filterResults = [self->sourceManager filterSources:self->_sources withFilter:self.filter];
        
        NSMutableArray *indexPaths = [NSMutableArray new];
        NSUInteger section = self->problems.count ? 1 : 0;
        for (ZBSource *source in sourcesToAdd) {
            NSUInteger row = [self->filterResults indexOfObject:source];
            if (row != NSNotFound) [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
}

- (void)removedSources:(NSNotification *)notification {
    if (!self.isViewLoaded) return;

    NSSet *sourcesToRemove = notification.userInfo[@"sources"];
    if (!sourcesToRemove.count) return;

    @synchronized (self) {
        NSMutableArray *indexPaths = [NSMutableArray new];
        NSUInteger section = self->problems.count ? 1 : 0;
        for (ZBSource *source in sourcesToRemove) {
            NSUInteger row = [self->filterResults indexOfObject:source];
            if (row != NSNotFound) [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
        }
        
        NSMutableArray *mutableSources = self->_sources.mutableCopy;
        [mutableSources removeObjectsInArray:sourcesToRemove.allObjects];
        self->_sources = mutableSources;
        self->filterResults = [self->sourceManager filterSources:self->_sources withFilter:self.filter];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
}

- (void)startedDownloadingSource:(NSNotification *)notification {
    if (!self.isViewLoaded) return;
    
    ZBSource *source = (ZBSource *)notification.userInfo[@"source"];
    if (!source || !source.remote) return;
    
    @synchronized (self) {
        NSUInteger row = [filterResults indexOfObject:source];
        if (row != NSNotFound) {
            NSUInteger section = problems.count ? 1 : 0;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            });
        }
    }
}

- (void)finishedImportingSource:(NSNotification *)notification {
    if (!self.isViewLoaded) return;
    
    ZBSource *source = (ZBSource *)notification.userInfo[@"source"];
    if (!source || !source.remote) return;
    
    @synchronized (self) {
        NSMutableArray *mutableSources = self->_sources.mutableCopy;
        NSUInteger realIndex = [mutableSources indexOfObject:source];
        [mutableSources replaceObjectAtIndex:realIndex withObject:source];
        self->_sources = mutableSources;
        
        NSUInteger section = problems.count ? 1 : 0;
        NSUInteger beforeIndex = [self->filterResults indexOfObject:source];
        self->filterResults = [self->sourceManager filterSources:self->_sources withFilter:self.filter];
        NSUInteger afterIndex = [self->filterResults indexOfObject:source];
        if (beforeIndex == NSNotFound && afterIndex == NSNotFound) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *beforeIndexPath = [NSIndexPath indexPathForRow:beforeIndex inSection:section];
            if (beforeIndex != afterIndex) { // The row moved
                NSIndexPath *afterIndexPath = [NSIndexPath indexPathForRow:afterIndex inSection:section];
                [self.tableView beginUpdates];
                if (beforeIndex != NSNotFound) [self.tableView deleteRowsAtIndexPaths:@[beforeIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                if (afterIndex != NSNotFound) [self.tableView insertRowsAtIndexPaths:@[afterIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
            } else { // They're in the same place :)
                [self.tableView reloadRowsAtIndexPaths:@[beforeIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        });
    }
}

- (void)finishedSourceRefresh {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isViewLoaded && self.refreshControl.isRefreshing) {
            [self.refreshControl endRefreshing];
        }
    });
}

@end
