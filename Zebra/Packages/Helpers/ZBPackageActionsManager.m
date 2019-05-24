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
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import <Queue/ZBQueue.h>
#import <UIColor+GlobalColors.h>
#import <Packages/Controllers/ZBPackageListTableViewController.h>

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

+ (BOOL)canHaveAction:(NSUInteger)possibleActions forPackage:(ZBPackage *)package queue:(ZBQueueType)q {
    return (possibleActions & q) && ![[ZBQueue sharedInstance] containsPackage:package queue:q];
}

+ (UIColor *)colorForAction:(ZBQueueType)queue {
    switch (queue) {
        case ZBQueueTypeInstall:
        case ZBQueueTypeUpgrade:
            return [UIColor systemBlueColor];
        case ZBQueueTypeReinstall:
            return [UIColor orangeColor];
        case ZBQueueTypeSelectable:
            return [UIColor purpleColor];
        case ZBQueueTypeRemove:
            return [UIColor systemRedColor];
        default:
            return nil;
    }
}

+ (NSArray <UITableViewRowAction *> *)rowActionsForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UITableViewController *)vc parent:(UIViewController *)parent completion:(void (^)(ZBQueueType))completion {
    NSMutableArray *actions = [NSMutableArray array];
    NSUInteger possibleActions = [package possibleActions];
    ZBQueue *queue = [ZBQueue sharedInstance];
    ZBPackageListTableViewController *controller = (ZBPackageListTableViewController *)vc;
    
    if ([self canHaveAction:possibleActions forPackage:package queue:ZBQueueTypeRemove]) {
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Remove" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [queue addPackage:package toQueue:ZBQueueTypeRemove];
            
            if ([controller respondsToSelector:@selector(configureNavigationButtons)]) {
                [controller configureNavigationButtons];
            }
            if (completion) {
                completion(ZBQueueTypeRemove);
            }
        }];
        [actions addObject:deleteAction];
    }
    
    if ([self canHaveAction:possibleActions forPackage:package queue:ZBQueueTypeInstall]) {
        UITableViewRowAction *installAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Install" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [queue addPackage:package toQueue:ZBQueueTypeInstall];
            
            if ([controller respondsToSelector:@selector(configureNavigationButtons)]) {
                [controller configureNavigationButtons];
            }
            if (completion) {
                completion(ZBQueueTypeInstall);
            }
        }];
        installAction.backgroundColor = [self colorForAction:ZBQueueTypeInstall];
        [actions addObject:installAction];
    }
    
    if ([self canHaveAction:possibleActions forPackage:package queue:ZBQueueTypeReinstall]) {
        UITableViewRowAction *reinstallAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Reinstall" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [queue addPackage:package toQueue:ZBQueueTypeReinstall];
            
            if ([controller respondsToSelector:@selector(configureNavigationButtons)]) {
                [controller configureNavigationButtons];
            }
            if (completion) {
                completion(ZBQueueTypeReinstall);
            }
        }];
        reinstallAction.backgroundColor = [self colorForAction:ZBQueueTypeReinstall];
        [actions addObject:reinstallAction];
    }
    
    if (possibleActions & ZBQueueTypeSelectable) {
        UITableViewRowAction *selectVerAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Select Ver." handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [self downgradePackage:package indexPath:indexPath viewController:vc parent:parent];
            
            if ([controller respondsToSelector:@selector(configureNavigationButtons)]) {
                [controller configureNavigationButtons];
            }
            if (completion) {
                completion(ZBQueueTypeSelectable);
            }
        }];
        selectVerAction.backgroundColor = [self colorForAction:ZBQueueTypeSelectable];
        [actions addObject:selectVerAction];
    }
    
    if ([self canHaveAction:possibleActions forPackage:package queue:ZBQueueTypeUpgrade]) {
        UITableViewRowAction *upgradeAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Upgrade" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [queue addPackage:package toQueue:ZBQueueTypeUpgrade];
            
            if ([controller respondsToSelector:@selector(configureNavigationButtons)]) {
                [controller configureNavigationButtons];
            }
            if (completion) {
                completion(ZBQueueTypeUpgrade);
            }
        }];
        upgradeAction.backgroundColor = [self colorForAction:ZBQueueTypeUpgrade];
        [actions addObject:upgradeAction];
    }
    
    return actions;
}

+ (NSArray <UIPreviewAction *> *)previewActionsForPackage:(ZBPackage *)package viewController:(UIViewController *)vc parent:(UIViewController *)parent {
    NSUInteger possibleActions = [package possibleActions];
    NSMutableArray *actions = [NSMutableArray array];
    ZBQueue *queue = [ZBQueue sharedInstance];
    
    if ([self canHaveAction:possibleActions forPackage:package queue:ZBQueueTypeRemove]) {
        UIPreviewAction *remove = [UIPreviewAction actionWithTitle:@"Remove" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
            [queue addPackage:package toQueue:ZBQueueTypeRemove];
        }];
        
        [actions addObject:remove];
    }
    
    if ([self canHaveAction:possibleActions forPackage:package queue:ZBQueueTypeInstall]) {
        UIPreviewAction *install = [UIPreviewAction actionWithTitle:@"Install" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
            BOOL purchased = [vc respondsToSelector:@selector(purchased)] ? [(ZBPackageDepictionViewController *)vc purchased] : NO;
            [self installPackage:package purchased:purchased];
        }];
        
        [actions addObject:install];
    }
    
    if ([self canHaveAction:possibleActions forPackage:package queue:ZBQueueTypeReinstall]) {
        UIPreviewAction *reinstall = [UIPreviewAction actionWithTitle:@"Reinstall" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
            [queue addPackage:package toQueue:ZBQueueTypeReinstall];
        }];
        
        [actions addObject:reinstall];
    }
    
    if (possibleActions & ZBQueueTypeSelectable) {
        UIPreviewAction *downgrade = [UIPreviewAction actionWithTitle:@"Select Ver." style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
            [self downgradePackage:package indexPath:nil viewController:vc parent:parent];
        }];
        
        [actions addObject:downgrade];
    }
    
    if ([self canHaveAction:possibleActions forPackage:package queue:ZBQueueTypeUpgrade]) {
        UIPreviewAction *upgrade = [UIPreviewAction actionWithTitle:@"Upgrade" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
            [queue addPackage:package toQueue:ZBQueueTypeUpgrade];
        }];
        
        [actions addObject:upgrade];
    }
    
    return actions;
}

+ (NSArray <UIAlertAction *> *)alertActionsForPackage:(ZBPackage *)package viewController:(UIViewController *)vc parent:(UIViewController *)parent {
    NSUInteger possibleActions = [package possibleActions];
    NSMutableArray *actions = [NSMutableArray array];
    ZBQueue *queue = [ZBQueue sharedInstance];
    
    if ([self canHaveAction:possibleActions forPackage:package queue:ZBQueueTypeRemove]) {
        UIAlertAction *remove = [UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [queue addPackage:package toQueue:ZBQueueTypeRemove];
            [self presentQueue:vc parent:parent];
        }];
        
        [actions addObject:remove];
    }
    
    if ([self canHaveAction:possibleActions forPackage:package queue:ZBQueueTypeInstall]) {
        UIAlertAction *install = [UIAlertAction actionWithTitle:@"Install" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            BOOL purchased = [vc respondsToSelector:@selector(purchased)] ? [(ZBPackageDepictionViewController *)vc purchased] : NO;
            [self installPackage:package purchased:purchased];
            [self presentQueue:vc parent:parent];
        }];
        
        [actions addObject:install];
    }
    
    if ([self canHaveAction:possibleActions forPackage:package queue:ZBQueueTypeReinstall]) {
        UIAlertAction *reinstall = [UIAlertAction actionWithTitle:@"Reinstall" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [queue addPackage:package toQueue:ZBQueueTypeReinstall];
            [self presentQueue:vc parent:parent];
        }];
        
        [actions addObject:reinstall];
    }
    
    if (possibleActions & ZBQueueTypeSelectable) {
        UIAlertAction *downgrade = [UIAlertAction actionWithTitle:@"Select Ver." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [ZBPackageActionsManager downgradePackage:package indexPath:nil viewController:vc parent:parent];
        }];
        
        [actions addObject:downgrade];
    }
    
    if ([self canHaveAction:possibleActions forPackage:package queue:ZBQueueTypeUpgrade]) {
        UIAlertAction *upgrade = [UIAlertAction actionWithTitle:@"Upgrade" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [queue addPackage:package toQueue:ZBQueueTypeUpgrade];
            [self presentQueue:vc parent:parent];
        }];
        
        [actions addObject:upgrade];
    }
    
    if ([package ignoreUpdates]) {
        UIAlertAction *unignore = [UIAlertAction actionWithTitle:@"Show Updates" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [package setIgnoreUpdates:false];
        }];
        
        [actions addObject:unignore];
    }
    else {
        UIAlertAction *ignore = [UIAlertAction actionWithTitle:@"Ignore Updates" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [package setIgnoreUpdates:true];
        }];
        
        [actions addObject:ignore];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL];
    [actions addObject:cancel];
    
    return actions;
}

+ (void)installPackage:(ZBPackage *)package purchased:(BOOL)purchased {
    if (purchased) {
        package.sileoDownload = TRUE;
    }
    
    ZBQueue *queue = [ZBQueue sharedInstance];
    [queue addPackage:package toQueue:ZBQueueTypeInstall];
}

+ (void)downgradePackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Downgrade %@ (%@)", [package name], [package version]] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (ZBPackage *downPackage in [package otherVersions]) {
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:[downPackage version] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ZBQueue *queue = [ZBQueue sharedInstance];
            [queue addPackage:downPackage toQueue:ZBQueueTypeInstall];
            
            [alert dismissViewControllerAnimated:true completion:nil];
            [self presentQueue:vc parent:parent];
        }];
        
        [alert addAction:action];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL];
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
