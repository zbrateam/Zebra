//
//  ZBSourceListViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/1/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBSourceListViewController.h"

#import <UI/Sources/Views/Cells/ZBSourceTableViewCell.h>
#import <UI/Sources/ZBSourceViewController.h>
#import <UI/ZBSidebarController.h>
#import <UI/Sources/ZBSourceAddViewController.h>

#import <Plains/Managers/PLSourceManager.h>
#import <Plains/Model/PLSource.h>
#import <SDWebImage/SDWebImage.h>

@interface ZBSourceListViewController () {
    PLSourceManager *sourceManager;
    NSArray *sources;
}
@end

@implementation ZBSourceListViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self.title = @"Sources";
        
        sourceManager = [PLSourceManager sharedInstance];
    }
    
    return self;
} 

- (void)viewDidLoad {
    [super viewDidLoad];

//#if TARGET_OS_IOS
//    self.refreshControl = [[UIRefreshControl alloc] init];
//    [self.refreshControl addTarget:self action:@selector(refreshSources) forControlEvents:UIControlEventValueChanged];
//#endif
    
    [self.tableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBSourceTableViewCell" bundle:nil] forCellReuseIdentifier:@"sourceTableViewCell"];
    
    [self loadSources];
}

#if TARGET_OS_MACCATALYST
- (NSArray *)toolbarItems {
    return @[@"refreshButton", @"addButton"];
}
#endif

- (void)addButton:(id)sender {
    ZBSourceAddViewController *addVC = [[ZBSourceAddViewController alloc] init];
    UINavigationController *addNav = [[UINavigationController alloc] initWithRootViewController:addVC];

    [self presentViewController:addNav animated:YES completion:nil];
}

- (void)refreshButton:(id)sender {
    [self refreshSources];
}

- (void)loadSources {
    if (!self.isViewLoaded) return;
    
    if (sources) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView transitionWithView:self.tableView duration:0.20f options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void) {
                [self.tableView reloadData];
            } completion:nil];
        });
    } else { // Load sources for the first time, every other access is done by the filter and delegate methods
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            self->sources = [[self->sourceManager sources] sortedArrayUsingSelector:@selector(compareByOrigin:)];
            [self loadSources];
        });
    }
}

- (void)refreshSources {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self->sourceManager refreshSources];
#if TARGET_OS_IOS
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
        });
#endif
    });
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sources.count;
}

- (ZBSourceTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceTableViewCell" forIndexPath:indexPath];
    
    PLSource *source = sources[indexPath.row];
    [cell setSource:source];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ZBSourceViewController *sourceController = [[ZBSourceViewController alloc] initWithSource:sources[indexPath.row]];
    [[self navigationController] pushViewController:sourceController animated:YES];
}

#pragma mark - Table View Delegate

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLSource *source = sources[indexPath.row];
    if ([source canRemove]) {
        UIContextualAction *removeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self->sourceManager removeSource:source];
            self->sources = NULL;
            [self loadSources];
            [self.tableView reloadData];
        }];
        return [UISwipeActionsConfiguration configurationWithActions:@[removeAction]];
    }
    return NULL;
}

@end
