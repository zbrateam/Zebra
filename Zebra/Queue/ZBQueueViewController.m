//
//  ZBQueueViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueueViewController.h"
#import "ZBLog.h"
#import "ZBAppDelegate.h"
#import "ZBQueue.h"
#import "ZBPackage.h"
#import "ZBConsoleViewController.h"
#import "UIColor+GlobalColors.h"
#import "ZBDevice.h"
#import "ZBThemeManager.h"
#import "ZBQueuePackageTableViewCell.h"

@import SDWebImage;
@import LNPopupController;

@interface ZBQueueViewController () {
    ZBQueue *queue;
    NSArray <NSArray *> *packages;
}
@end

@implementation ZBQueueViewController

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [super init];
    self = [storyboard instantiateViewControllerWithIdentifier:@"queueController"];
    
    if (self) {
        queue = [ZBQueue sharedQueue];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyLocalization];
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0.0;
    }
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 44;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableView registerClass:[ZBQueuePackageTableViewCell class] forCellReuseIdentifier:@"ZBQueuePackageTableViewCell"];
    // self.tableView.alwaysBounceVertical = false;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor primaryTextColor]}];
    
    [self refreshTable];
}

- (void)applyLocalization {
    self.navigationItem.title = NSLocalizedString(@"Queue", @"");
    self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Confirm", @"");
    self.navigationItem.leftBarButtonItems[1].title = NSLocalizedString(@"Clear", @"");
}

- (void)refreshTable {
    packages = [queue topDownQueue];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.rightBarButtonItem.enabled = ![self->queue hasIssues];
        [self.tableView reloadData];
        
        if (self->packages.count == 0) {
            [self->queue clear];
        }
    });
}

#pragma mark - Button actions

- (IBAction)dismissQueue:(id)sender {
    [[ZBAppDelegate tabBarController] closePopupAnimated:YES completion:nil];
}

- (IBAction)clearQueue:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure?", @"") message:NSLocalizedString(@"Are you sure you want to clear the Queue?", @"") preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:NSLocalizedString(@"Confirm", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self->queue clear];
    }];
    [alert addAction:confirm];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    
    alert.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)confirm:(id)sender {
    if ([queue containsEssentialOrRequiredPackage]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure?", @"") message:NSLocalizedString(@"One or more of the packages in the Queue for removal is essential or required. It is not recommended to proceed unless you know exactly what you are doing. Removing these packages could cause irreversible damage to your device and might result in a full restore.", @"") preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:NSLocalizedString(@"Confirm", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            ZBConsoleViewController *console = [[ZBConsoleViewController alloc] init];
            [self.navigationController pushViewController:console animated:YES];
        }];
        [alert addAction:confirm];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        
        alert.popoverPresentationController.barButtonItem = sender;
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        ZBConsoleViewController *console = [[ZBConsoleViewController alloc] init];
        [self.navigationController pushViewController:console animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return packages.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return packages[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray <NSNumber *> *actions = [queue actionsToPerform];
    if (actions.count == 0) {
        return @"No Actions to Perform";
    }
    if (section > actions.count - 1) {
        return [NSString stringWithFormat:@"Unrecognized Action %ld", (long)section];
    }
    ZBQueueType action = actions[section].intValue;
    NSString *downloadSize = [queue downloadSizeForQueue:action];
    NSMutableString *title = [[queue displayableNameForQueueType:action] mutableCopy];
    if (downloadSize) [title appendFormat:@" (%@: %@)", NSLocalizedString(@"Download Size", @""), [queue downloadSizeForQueue:action]];
    
    return title;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
    contentView.backgroundColor = [UIColor tableViewBackgroundColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.numberOfLines = 0;
    label.textColor = [UIColor primaryTextColor];
    label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:label];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[label]-16-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[label]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
    
    return contentView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBQueuePackageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZBQueuePackageTableViewCell" forIndexPath:indexPath];
    ZBPackage *package = packages[indexPath.section][indexPath.row];
    [cell setPackage:package onQueue:self->queue];
     
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = packages[indexPath.section][indexPath.row];
    if ([package isEssentialOrRequired] && [queue contains:package inQueue:ZBQueueTypeRemove]) {
        if ([package removedBy] != NULL) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Required Package", @"") message:[NSString stringWithFormat:NSLocalizedString(@"%@ is a required package and must be removed because it depends on %@. %@ should NOT be removed unless you know exactly what you are doing!", @""), [package name], [[package removedBy] name], [[package removedBy] name]] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove from Queue", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self->queue removePackage:package];
                [self refreshTable];
            }];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Confirm", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [alert dismissViewControllerAnimated:YES completion:nil];
            }];
            
            [alert addAction:deleteAction];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Required Package", @"") message:[NSString stringWithFormat:NSLocalizedString(@"%@ is a required package. It should NOT be removed unless you know exactly what you are doing!", @""), [package name]] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove from Queue", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self->queue removePackage:package];
                [self refreshTable];
            }];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Confirm", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [alert dismissViewControllerAnimated:YES completion:nil];
            }];
            
            [alert addAction:deleteAction];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else if ([package hasIssues]) {
        NSMutableString *message = [[NSString stringWithFormat:NSLocalizedString(@"%@ has issues that cannot be resolved:", @""), [package name]] mutableCopy];
        for (NSString *issue in [package issues]) {
            [message appendFormat:@"\n%@", issue];
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Issues", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove from Queue", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self->queue removePackage:package];
            [self refreshTable];
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:okAction];
        [alert addAction:deleteAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if ([package removedBy] != nil) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"%@ must be removed because it depends on %@", @""), [package name], [[package removedBy] name]];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Required Package", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if ([package dependencyOf].count > 0) {
        NSMutableString *message = [[NSString stringWithFormat:NSLocalizedString(@"%@ is required by:", @""), [package name]] mutableCopy];
        for (ZBPackage *parent in [package dependencyOf]) {
            [message appendFormat:@"\n%@", [parent name]];
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Required Package", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Swipe actions

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:[ZBDevice useIcon] ? @"✗" : NSLocalizedString(@"Delete", @"") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
    }];
    return @[deleteAction];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [queue removePackage:packages[indexPath.section][indexPath.row]];
    [self refreshTable];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
}

@end
