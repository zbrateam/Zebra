//
//  ZBQueueViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueueViewController.h"

#import <UI/Packages/Views/Cells/ZBPackageTableViewCell.h>
#import <UI/Common/Views/ZBBoldTableViewHeaderView.h>
#import <UI/Console/ZBConsoleViewController.h>

#import <Plains/PLPackage.h>
#import <Plains/PLQueue.h>

@interface ZBQueueViewController () {
    PLQueue *queue;
    NSArray <NSArray <PLPackage *> *> *packages;
}
@end

@implementation ZBQueueViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        queue = [PLQueue sharedInstance];
        self.title = @"Queue";
        
        [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
        [self.tableView registerNib:[UINib nibWithNibName:@"ZBBoldTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"BoldTableViewHeaderView"];

        [self.tableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
        [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self->packages = queue.packages;
    [self.tableView reloadData];
    
#if TARGET_OS_MACCATALYST
    [self.navigationController setNavigationBarHidden:YES animated:NO];
#endif
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return packages.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return packages[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
    
    PLPackage *package = packages[indexPath.section][indexPath.row];
    [cell setPackage:package];
    
    return cell;
}

#pragma mark - Table View Delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (packages[section].count == 0) return NULL;
    
    ZBBoldTableViewHeaderView *cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"BoldTableViewHeaderView"];
    NSString *title;
    switch (section) {
        case PLQueueInstall:
            title = @"Install";
            break;
        case PLQueueRemove:
            title = @"Remove";
            break;
        case PLQueueReinstall:
            title = @"Reinstall";
            break;
        case PLQueueUpgrade:
            title = @"Upgrade";
            break;
        default:
            title = @"Unknown";
            break;
    }
    cell.titleLabel.text = title;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    if (packages[section].count == 0) return 0;
    return 45;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *clearAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Remove" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        PLPackage *package = self->packages[indexPath.section][indexPath.row];
        [self->queue removePackage:package];
        self->packages = self->queue.packages;
        [self.tableView reloadData];
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[clearAction]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIWindow *window = [UIApplication sharedApplication].windows[0];
    ZBConsoleViewController *console = [[ZBConsoleViewController alloc] init];
    if (window.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        [[self navigationController] pushViewController:console animated:YES];
    } else {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:console];
        [self presentViewController:navController animated:YES completion:nil];
    }
}

@end
