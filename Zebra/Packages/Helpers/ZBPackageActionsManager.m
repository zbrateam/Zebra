//
//  ZBPackageActionsManager.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 13/5/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageActionsManager.h"
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageTableViewCell.h>
#import <Queue/ZBQueue.h>
#import <UIColor+GlobalColors.h>

@implementation ZBPackageActionsManager

+ (void)presentQueue:(UIViewController *)vc parent:(UIViewController *)parent {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UINavigationController *qvc = [storyboard instantiateViewControllerWithIdentifier:@"queueController"];
    
    if (vc.navigationController == NULL && parent != NULL) {
        [parent presentViewController:qvc animated:true completion:nil];
    }
    else {
        [vc presentViewController:qvc animated:true completion:nil];
    }
}

+ (NSArray *)actionsForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UITableViewController *)vc parent:(UIViewController *)parent {
    NSMutableArray *actions = [NSMutableArray array];
    NSUInteger possibleActions = [package possibleActions];
    ZBQueue *queue = [ZBQueue sharedInstance];
    
    if (possibleActions & ZBQueueTypeRemove) {
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Remove" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [queue addPackage:package toQueue:ZBQueueTypeRemove];
        }];
        [actions addObject:deleteAction];
    }
    
    if (possibleActions & ZBQueueTypeInstall) {
        UITableViewRowAction *installAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Install" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [queue addPackage:package toQueue:ZBQueueTypeInstall];
        }];
        installAction.backgroundColor = [UIColor systemBlueColor];
        [actions addObject:installAction];
    }
    
    if (possibleActions & ZBQueueTypeReinstall) {
        UITableViewRowAction *reinstallAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Reinstall" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [queue addPackage:package toQueue:ZBQueueTypeReinstall];
        }];
        reinstallAction.backgroundColor = [UIColor orangeColor];
        [actions addObject:reinstallAction];
    }
    
    if (possibleActions & ZBQueueTypeDowngrade) {
        UITableViewRowAction *downgradeAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Downgrade" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [self downgradePackage:package indexPath:indexPath viewController:vc parent:parent];
        }];
        downgradeAction.backgroundColor = [UIColor purpleColor];
        [actions addObject:downgradeAction];
    }
    
    if (possibleActions & ZBQueueTypeUpgrade) {
        UITableViewRowAction *upgradeAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Upgrade" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [queue addPackage:package toQueue:ZBQueueTypeUpgrade];
        }];
        upgradeAction.backgroundColor = [UIColor systemBlueColor];
        [actions addObject:upgradeAction];
    }
    
    return actions;
}

+ (void)downgradePackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Downgrade %@", [package name]] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (ZBPackage *downPackage in [package otherVersions]) {
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:[downPackage version] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ZBQueue *queue = [ZBQueue sharedInstance];
            [queue addPackage:downPackage toQueue:ZBQueueTypeInstall];
            
            [alert dismissViewControllerAnimated:true completion:nil];
            [self presentQueue:vc parent:parent];
        }];
        
        [alert addAction:action];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:true completion:nil];
    }];
    
    [alert addAction:cancel];
    
    if (indexPath) {
        ZBPackageTableViewCell *cell = [((UITableViewController *)vc).tableView cellForRowAtIndexPath:indexPath];
        alert.popoverPresentationController.sourceView = cell;
        alert.popoverPresentationController.sourceRect = cell.bounds;
    }
    else {
        alert.popoverPresentationController.barButtonItem = vc.navigationItem.rightBarButtonItem;
    }
    
    [vc presentViewController:alert animated:true completion:nil];
}

@end
