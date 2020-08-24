//
//  ZBSourceListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/3/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBSourceListViewController.h"
#import "ZBSourceAddViewController.h"

#import <Tabs/Sources/Helpers/ZBSource.h>
#import <Tabs/Sources/Helpers/ZBSourceManager.h>
#import <Tabs/Sources/Views/ZBSourceTableViewCell.h>

@interface ZBSourceListViewController () {
    UISearchController *searchController;
    ZBSourceManager *sourceManager;
}
@end

@implementation ZBSourceListViewController

#pragma mark - Initializers

- (id)init {
    if (@available(iOS 13.0, *)) {
        self = [super initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [super initWithStyle:UITableViewStyleGrouped];
    }
    
    if (self) {
        self.title = NSLocalizedString(@"Sources", @"");
        
        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.obscuresBackgroundDuringPresentation = NO;
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        sourceManager = [ZBSourceManager sharedInstance];
        sources = sourceManager.sources;
        filteredSources = [sources copy];
        
        [[ZBDatabaseManager sharedInstance] addDatabaseDelegate:self];
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(presentAddView)];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBSourceTableViewCell" bundle:nil] forCellReuseIdentifier:@"sourceCell"];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.navigationItem.searchController = searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = YES;
}

- (void)presentAddView {
    ZBSourceAddViewController *addView = [[ZBSourceAddViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addView];
    
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return filteredSources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceCell"];
    [cell setSource:filteredSources[indexPath.row]];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBBaseSource *source = filteredSources[indexPath.row];
    
    BOOL busy = [sourceManager isSourceBusy:source];
    [(ZBSourceTableViewCell *)cell setSpinning:busy];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = filteredSources[indexPath.row];
    
    UIContextualAction *copyAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:NSLocalizedString(@"Copy",@"") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:source.repositoryURI];
        completionHandler(YES);
    }];
    
    copyAction.backgroundColor = [UIColor systemTealColor];
    copyAction.image = [UIImage systemImageNamed:@"doc.on.clipboard.fill"];
    
    return [UISwipeActionsConfiguration configurationWithActions:@[copyAction]];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = filteredSources[indexPath.row];
    
    NSMutableArray *actions = [NSMutableArray new];
    if ([source canDelete]) {
        UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:NSLocalizedString(@"Delete", @"") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            NSError *error = NULL;
            [self->sourceManager removeSources:[NSSet setWithArray:@[source]] error:&error];
            
            completionHandler(error == NULL);
        }];
        deleteAction.image = [UIImage systemImageNamed:@"delete.right.fill"];
        [actions addObject:deleteAction];
    }
    
    UIContextualAction *refreshAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:NSLocalizedString(@"Refresh", @"") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self->sourceManager refreshSources:[NSSet setWithArray:@[source]] error:nil];
    }];
    refreshAction.image = [UIImage systemImageNamed:@"arrow.clockwise.circle.fill"];
    [actions addObject:refreshAction];
    
    return [UISwipeActionsConfiguration configurationWithActions:actions];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(nonnull UISearchController *)searchController {
    NSString *searchTerm = searchController.searchBar.text;
    if ([[searchTerm stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        filteredSources = [sources copy];
    }
    else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(repositoryURI CONTAINS[cd] %@) OR (origin CONTAINS[cd] %@)", searchTerm, searchTerm];
        
        filteredSources = [[sources filteredArrayUsingPredicate:predicate] mutableCopy];
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - ZBSourceDelegate

- (void)startedSourceRefresh {
    
}

- (void)startedRefreshForSource:(ZBBaseSource *)source {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[filteredSources indexOfObject:(ZBSource *)source] inSection:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)finishedRefreshForSource:(ZBBaseSource *)source warnings:(NSArray *)warnings errors:(NSArray *)errors {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[filteredSources indexOfObject:(ZBSource *)source] inSection:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)finishedSourceRefresh {
    
}

- (void)addedSources:(NSSet<ZBBaseSource *> *)sources {
    
}

- (void)removedSources:(NSSet<ZBBaseSource *> *)sources {
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (ZBSource *source in sources) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self->sources indexOfObject:source] inSection:0];
        [indexPaths addObject:indexPath];
    }
    
    self->sources = sourceManager.sources;
    self->filteredSources = [self->sources copy];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
