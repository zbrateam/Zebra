//
//  ZBSourceListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/3/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBSourceListViewController.h"
#import "ZBSourceAddViewController.h"
#import "ZBSourceSectionsListTableViewController.h"

#import <ZBDevice.h>

#import <Tabs/Sources/Helpers/ZBSource.h>
#import <Tabs/Sources/Helpers/ZBSourceManager.h>
#import <Tabs/Sources/Views/ZBSourceTableViewCell.h>

@interface ZBSourceListViewController () {
    UISearchController *searchController;
    ZBSourceManager *sourceManager;
    NSMutableArray *sourcesToRemove;
    UIBarButtonItem *addButton;
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
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        
        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.obscuresBackgroundDuringPresentation = NO;
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        sourceManager = [ZBSourceManager sharedInstance];
        sources = [sourceManager.sources mutableCopy];
        filteredSources = [sources copy];
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(presentAddView)];
    self.navigationItem.rightBarButtonItem = addButton;
    
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

- (void)removeSources {
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to remove %lu sources?", @""), (unsigned long)sourcesToRemove.count];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure?", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self->sourceManager removeSources:[NSSet setWithArray:self->sourcesToRemove] error:nil];
    }];
    [alert addAction:confirm];
    
    UIAlertAction *deny = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:deny];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
        if (!sourcesToRemove) sourcesToRemove = [NSMutableArray new];
        
        UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeSources)];
        deleteButton.enabled = NO;
        self.navigationItem.rightBarButtonItems = @[addButton, deleteButton];
    }
    else {
        self.navigationItem.rightBarButtonItems = @[addButton];
        [sourcesToRemove removeAllObjects];
    }
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = filteredSources[indexPath.row];
    return [source canDelete];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBBaseSource *source = filteredSources[indexPath.row];
    
    BOOL busy = [sourceManager isSourceBusy:source];
    [(ZBSourceTableViewCell *)cell setSpinning:busy];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = filteredSources[indexPath.row];
    if (!self.editing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        ZBSourceSectionsListTableViewController *sections = [[ZBSourceSectionsListTableViewController alloc] initWithSource:source editOnly:NO];
        [self.navigationController pushViewController:sections animated:YES];
    }
    else {
        [sourcesToRemove addObject:source];
        
        self.navigationItem.rightBarButtonItems[1].enabled = sourcesToRemove.count;
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        ZBSource *source = filteredSources[indexPath.row];
        if ([sourcesToRemove containsObject:source]) {
            [sourcesToRemove removeObject:source];
        }
        self.navigationItem.rightBarButtonItems[1].enabled = sourcesToRemove.count;
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = filteredSources[indexPath.row];
    
    UIContextualAction *copyAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:NSLocalizedString(@"Copy",@"") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:source.repositoryURI];
        completionHandler(YES);
    }];
    
    copyAction.image = [UIImage imageNamed:@"doc_fill"];
    copyAction.backgroundColor = [UIColor systemTealColor];
    
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
        deleteAction.image = [UIImage imageNamed:@"delete_left"];
        [actions addObject:deleteAction];
    }
    
    UIContextualAction *refreshAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:NSLocalizedString(@"Refresh", @"") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self->sourceManager refreshSources:[NSSet setWithArray:@[source]] useCaching:YES error:nil];
    }];
    refreshAction.image = [UIImage imageNamed:@"arrow_clockwise"];
    [actions addObject:refreshAction];
    
    return [UISwipeActionsConfiguration configurationWithActions:actions];
}

#pragma mark - UISearchResultsUpdating

- (void)filterSourcesForSearchTerm:(NSString *)searchTerm {
    if ([[searchTerm stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        filteredSources = [sources copy];
    }
    else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(repositoryURI CONTAINS[cd] %@) OR (origin CONTAINS[cd] %@)", searchTerm, searchTerm];
        
        filteredSources = [sources filteredArrayUsingPredicate:predicate];
    }
}

- (void)updateSearchResultsForSearchController:(nonnull UISearchController *)searchController {
    NSString *searchTerm = searchController.searchBar.text;
    [self filterSourcesForSearchTerm:searchTerm];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - ZBSourceDelegate

- (void)startedDownloadForSource:(ZBBaseSource *)source {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[filteredSources indexOfObject:(ZBSource *)source] inSection:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)finishedDownloadForSource:(ZBBaseSource *)source warnings:(NSArray *)warnings errors:(NSArray *)errors {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[filteredSources indexOfObject:(ZBSource *)source] inSection:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)startedImportForSource:(ZBBaseSource *)source {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[filteredSources indexOfObject:(ZBSource *)source] inSection:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)finishedImportForSource:(ZBBaseSource *)source errors:(NSArray<NSError *> *)errors {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:[self->filteredSources indexOfObject:(ZBSource *)source] inSection:0];
        
        self->sources = [self->sourceManager.sources mutableCopy];
        [self filterSourcesForSearchTerm:self->searchController.searchBar.text];
        
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:[self->filteredSources indexOfObject:(ZBSource *)source] inSection:0];
        
        if ([oldIndexPath isEqual:newIndexPath]) {
            [self.tableView reloadRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }
    });
}

- (void)addedSources:(NSSet<ZBBaseSource *> *)sources {
    self->sources = [sourceManager.sources mutableCopy];
    [self filterSourcesForSearchTerm:searchController.searchBar.text];
    
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (ZBSource *source in sources) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self->filteredSources indexOfObject:source] inSection:0];
        [indexPaths addObject:indexPath];
    }
    
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)removedSources:(NSSet<ZBBaseSource *> *)sources {
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (ZBSource *source in sources) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self->filteredSources indexOfObject:source] inSection:0];
        [indexPaths addObject:indexPath];
    }
    
    self->sources = [sourceManager.sources mutableCopy];
    [self filterSourcesForSearchTerm:searchController.searchBar.text];
    
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
