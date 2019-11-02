//
//  ZBQueueViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueueViewController.h"
#import <ZBLog.h>
#import <ZBAppDelegate.h>
#import "ZBQueue.h"
#import <Packages/Helpers/ZBPackage.h>
#import <Console/ZBConsoleViewController.h>
#import <UIColor+GlobalColors.h>
#import <ZBDevice.h>

@import SDWebImage;
@import LNPopupController;

@interface ZBQueueViewController () {
    ZBQueue *queue;
    NSArray *packages;
}
@end

@implementation ZBQueueViewController

- (void)loadView {
    [super loadView];
    queue = [ZBQueue sharedQueue];
    packages = [queue topDownQueue];
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self refreshBarButtons];
    [self applyLocalization];
    self.title = NSLocalizedString(@"Queue", @"");
}

- (void)applyLocalization {
    self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Confirm", @"");
    self.navigationItem.leftBarButtonItems[0].title = NSLocalizedString(@"Continue", @"");
    self.navigationItem.leftBarButtonItems[1].title = NSLocalizedString(@"Clear", @"");
}

- (void)clearQueueBarData {
    self.navigationController.popupItem.title = NSLocalizedString(@"Queue cleared", @"");
    self.navigationController.popupItem.subtitle = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([ZBDevice darkModeEnabled]) {
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    }
    else {
        [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    }
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor cellPrimaryTextColor]}];
    [self refreshTable];
}

- (IBAction)confirm:(id)sender {
    ZBConsoleViewController *console = [[ZBConsoleViewController alloc] init];
    [self.navigationController pushViewController:console animated:true];
}

- (IBAction)abort:(id)sender {
    if (!self.navigationItem.rightBarButtonItem.enabled) {
        [queue clear];
        [self clearQueueBarData];
        [[ZBAppDelegate tabBarController] dismissPopupBarAnimated:YES completion:nil];
    } else {
        [[ZBAppDelegate tabBarController] closePopupAnimated:YES completion:nil];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (IBAction)clear:(id)sender {
    [self abort:nil];
}

- (void)refreshBarButtons {
    if ([queue hasIssues]) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.leftBarButtonItems[0].title = NSLocalizedString(@"Abort", @"");
        self.navigationItem.leftBarButtonItems[1].title = NSLocalizedString(@"Clear", @"");
        self.navigationItem.leftBarButtonItems[1].enabled = YES;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.leftBarButtonItems[0].title = NSLocalizedString(@"Continue", @"");
        self.navigationItem.leftBarButtonItems[1].enabled = NO;
    }
}

- (void)refreshTable {
    if ([ZBQueue count] == 0) {
        [queue clear];
        [self clearQueueBarData];
        [[ZBAppDelegate tabBarController] dismissPopupBarAnimated:YES completion:nil];
        return;
    }
    
    [self refreshBarButtons];
    packages = [queue topDownQueue];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [packages count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [packages[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    ZBQueueType action = [queue actionsToPerform][section].intValue;
    if (action == ZBQueueTypeInstall || action == ZBQueueTypeReinstall || action == ZBQueueTypeUpgrade || action == ZBQueueTypeDowngrade) {
        return [NSString stringWithFormat:@"%@ %@: %@)", [queue displayableNameForQueueType:action useIcon:false], NSLocalizedString(@"Download Size", @""), [queue downloadSizeForQueue:action]];
    }
    return [queue displayableNameForQueueType:action useIcon:false];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    // Text Color
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.textColor = [UIColor cellPrimaryTextColor];
        header.tintColor = [UIColor clearColor];
        [(UIView *)[header valueForKey:@"_backgroundView"] setBackgroundColor:[UIColor tableViewBackgroundColor]];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"QueuePackageTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    cell.backgroundColor = [UIColor cellBackgroundColor];
    
    ZBPackage *package = packages[indexPath.section][indexPath.row];
    if ([[package dependencyOf] count] > 0 || [package hasIssues] || [package removedBy] != NULL)  {
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    NSString *section = [package sectionImageName];
    if (package.iconPath) {
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:package.iconPath] placeholderImage:[UIImage imageNamed:@"Other"]];
        cell.imageView.layer.cornerRadius = 10;
        cell.imageView.clipsToBounds = YES;
    } else {
        UIImage *sectionImage = [UIImage imageNamed:section];
        if (sectionImage != NULL) {
            cell.imageView.image = sectionImage;
            cell.imageView.layer.cornerRadius = 10;
            cell.imageView.clipsToBounds = YES;
        }
    }
    
    cell.textLabel.text = package.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", package.identifier, package.version];
    
    if ([package hasIssues]) {
        [cell setTintColor:[UIColor systemPinkColor]];
        cell.textLabel.textColor = [UIColor systemPinkColor];
        cell.detailTextLabel.textColor = [UIColor systemPinkColor];
    }
    else {
        [cell setTintColor:[UIColor tintColor]];
        cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
        cell.detailTextLabel.textColor = [UIColor cellSecondaryTextColor];
    }
    
    CGSize itemSize = CGSizeMake(35, 35);
    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
    [cell.imageView.image drawInRect:imageRect];
    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = packages[indexPath.section][indexPath.row];
    if ([package hasIssues]) {
        NSMutableString *message = [[NSString stringWithFormat:NSLocalizedString(@"%@ has issues that cannot be resolved:", @""), [package name]] mutableCopy];
        for (NSString *issue in [package issues]) {
            [message appendFormat:@"\n%@", issue];
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Issues", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self->queue removePackage:package];
            [self refreshTable];
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:true completion:nil];
        }];
        [alert addAction:deleteAction];
        [alert addAction:okAction];
        [self presentViewController:alert animated:true completion:nil];
    }
    else if ([package removedBy] != NULL) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"%@ must be removed because it depends on %@", @""), [package name], [[package removedBy] name]];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Required Package", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:true completion:nil];
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:true completion:nil];
    }
    else if ([[package dependsOn] count] > 0) {
        NSMutableString *message = [[NSString stringWithFormat:NSLocalizedString(@"%@ is required by:", @""), [package name]] mutableCopy];
        for (ZBPackage *parent in [package dependencyOf]) {
            [message appendFormat:@"\n%@", [parent name]];
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Required Package", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:true completion:nil];
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:true completion:nil];
    }
}

//swipe actions

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Delete", @"") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
    }];
    return @[deleteAction];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [queue removePackage:packages[indexPath.section][indexPath.row]];
    [self refreshTable];
}

@end
