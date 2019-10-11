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
#import <Queue/ZBQueuedPackage.h>

@import SDWebImage;
@import LNPopupController;

@interface ZBQueueViewController () {
    ZBQueue *queue;
}
@end

@implementation ZBQueueViewController

- (void)loadView {
    [super loadView];
    queue = [ZBQueue sharedQueue];
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
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
    //idk
}

- (void)refreshBarButtons {
    //idk
}

- (void)refreshTable {
    [self refreshBarButtons];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[queue actionsToPerform] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *action = [[queue actionsToPerform] objectAtIndex:section];
    return [queue numberOfPackagesInQueueKey:action];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = [[queue actionsToPerform] objectAtIndex:section];
    if ([title isEqualToString:@"Install"] || [title isEqualToString:@"Reinstall"] || [title isEqualToString:@"Upgrade"]) {
        ZBQueueType type = [queue queueTypeFromKey:title];
        if (type) {
            double totalDownloadSize = 0;
            NSArray *packages = [queue queueFromType:type];
            for (ZBPackage *package in packages) {
                ZBPackage *truePackage = package;
                totalDownloadSize += [truePackage numericSize];
            }
            if (totalDownloadSize) {
                NSString *unit = @"bytes";
                if (totalDownloadSize > 1024 * 1024) {
                    totalDownloadSize /= 1024 * 1024;
                    unit = @"MB";
                } else if (totalDownloadSize > 1024) {
                    totalDownloadSize /= 1024;
                    unit = @"KB";
                }
                return [NSString stringWithFormat:@"%@ (Download Size: %.2f %@)", title, totalDownloadSize, unit];
            }
        }
    }
    return title;
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
//    NSString *action = [[queue actionsToPerform] objectAtIndex:indexPath.section];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
//    cell.backgroundColor = [UIColor cellBackgroundColor];
    
//    if ([action isEqualToString:@"Unresolved Dependencies"]) {
//        cell.backgroundColor = [UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0];
//
//        NSArray *failedQ = [queue failedDepQueue];
//        cell.textLabel.text = failedQ[indexPath.row][0];
//        cell.detailTextLabel.text = [NSString stringWithFormat:@"Could not resolve dependency for %@", [(ZBPackage *)failedQ[indexPath.row][1] name]];
//
//        return cell;
//    } else if ([action isEqualToString:@"Conflictions"]) {
//        cell.backgroundColor = [UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0];
//
//        NSArray *failedQ = [queue failedConQueue];
//
//        int type = [failedQ[indexPath.row][0] intValue];
//        ZBPackage *confliction = (ZBPackage *)failedQ[indexPath.row][1];
//        ZBPackage *package = (ZBPackage *)failedQ[indexPath.row][2];
//
//        cell.textLabel.text = confliction.name;
//        switch (type) {
//            case 0:
//                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ conflicts with %@", package.name, confliction.name];
//                break;
//            case 1:
//                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ conflicts with %@", confliction.name, package.name];
//                break;
//            case 2:
//                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ depends on %@", confliction.name, package.name];
//                break;
//            default:
//                cell.detailTextLabel.text = @"Are you proud of yourself?";
//                break;
//        }
//
//        return cell;
//    }
    
    ZBQueuedPackage *queuedPackage = [queue packageAtIndexPath:indexPath];
    ZBPackage *package = [queuedPackage package];
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

@end
