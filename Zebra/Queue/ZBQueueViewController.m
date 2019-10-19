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
    NSLog(@"Queue Install: %@", [queue queueFromType:ZBQueueTypeInstall]);
    packages = [queue topDownQueue];
    NSLog(@"Queue Install2: %@", [queue queueFromType:ZBQueueTypeInstall]);
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self refreshBarButtons];
    self.title = @"Queue";
}

- (void)clearQueueBarData {
    self.navigationController.popupItem.title = @"Queue cleared";
    self.navigationController.popupItem.subtitle = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    NSLog(@"Dependency Queue: %@", [queue dependencyQueue]);
    [self refreshTable];
}

- (IBAction)confirm:(id)sender {
    [self clearQueueBarData];
    ZBTabBarController *tab = [ZBAppDelegate tabBarController];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBConsoleViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"consoleViewController"];
    [tab presentViewController:vc animated:YES completion:^(void) {
        [tab dismissPopupBarAnimated:NO completion:nil];
    }];
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
        self.navigationItem.leftBarButtonItems[0].title = @"Abort";
        self.navigationItem.leftBarButtonItems[1].title = @"Clear";
        self.navigationItem.leftBarButtonItems[1].enabled = YES;
    }
    else {
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.leftBarButtonItems[0].title = @"Continue";
        self.navigationItem.leftBarButtonItems[1].enabled = NO;
    }
}

- (void)refreshTable {
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
    ZBQueueType action;
    [[[queue actionsToPerform] objectAtIndex:section] getValue:&action];
    if (action == ZBQueueTypeInstall || action == ZBQueueTypeReinstall || action == ZBQueueTypeUpgrade || action == ZBQueueTypeDowngrade) {
        return [NSString stringWithFormat:@"%@ (Download Size: %@)", [queue displayableNameForQueueType:action useIcon:false], [queue downloadSizeForQueue:action]];
    }
    return [queue displayableNameForQueueType:action useIcon:false];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    // Text Color
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.textColor = [UIColor cellPrimaryTextColor];
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
    if ([[package dependencyOf] count] == 0)  {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
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
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        [cell setTintColor:[UIColor systemPinkColor]];
        cell.textLabel.textColor = [UIColor systemPinkColor];
        cell.detailTextLabel.textColor = [UIColor systemPinkColor];
    }
    else {
        cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
        cell.detailTextLabel.textColor = [UIColor cellSecondaryTextColor];
    }
    
//    NSMutableString *details = [NSMutableString string];
//    ZBPackage *replacedPackage = [queue packageReplacedBy:package];
//    if (replacedPackage) {
//        [details appendString:[NSString stringWithFormat:@"%@ (%@ -> %@)", package.identifier, replacedPackage.version, package.version]];
//    } else {
//        [details appendString:[NSString stringWithFormat:@"%@ (%@)", package.identifier, package.version]];
//    }
//    
//    NSMutableArray <ZBPackage *> *requiredPackages = [queue packagesRequiredBy:package];
//    if (requiredPackages) {
//        ZBQueueType queue = [queue keyToQueue:action];
//        NSMutableArray <NSString *> *requiredPackageNames = [NSMutableArray array];
//        for (ZBPackage *package in requiredPackages) {
//            [requiredPackageNames addObject:package.name];
//        }
//        [details appendString:[NSString stringWithFormat:queue == ZBQueueTypeRemove ? @" (Removed by %@)" : @" (Required by %@)", [requiredPackageNames componentsJoinedByString:@", "]]];
//    }
//    cell.detailTextLabel.text = details;
    
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
        NSMutableString *message = [@"This package has issues that cannot be resolved" mutableCopy];
        for (NSString *issue in [package issues]) {
            [message appendFormat:@"\n%@", issue];
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Issues" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self->queue removePackage:package];
            [self refreshTable];
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:true completion:nil];
        }];
        [alert addAction:deleteAction];
        [alert addAction:okAction];
        [self presentViewController:alert animated:true completion:nil];
    }
    else if ([[package dependsOn] count] > 0) {
        NSMutableString *message = [[NSString stringWithFormat:@"%@ is required by:", [package name]] mutableCopy];
        for (ZBPackage *parent in [package dependencyOf]) {
            [message appendFormat:@"\n%@", [parent name]];
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Required Package" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:true completion:nil];
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:true completion:nil];
    }
}

@end
