//
//  ZBPackageActionsManager.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 13/5/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageActionsManager.h"
#import "ZBPackage.h"
#import "ZBPackageActionType.h"

#import <ZBDevice.h>
#import <ZBAppDelegate.h>
#import <Sources/Helpers/ZBSource.h>
#import <Packages/Views/ZBPackageTableViewCell.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import <Queue/ZBQueue.h>
#import <UIColor+GlobalColors.h>
#import <Packages/Controllers/ZBPackageListTableViewController.h>


@implementation ZBPackageActionsManager

#pragma mark - Calculating Actions

+ (NSArray *)actionsForPackage:(ZBPackage *)package {
    NSMutableArray *actions = [NSMutableArray new];
    ZBQueue *queue = [ZBQueue sharedQueue];
    
    if ([[package repo] repoID] == -1) {
        return 0; // No actions for virtual dependencies
    }
    if ([package isInstalled:NO]) {
        // If the package is installed then we can show other options
        if (![queue contains:package inQueue:ZBQueueTypeReinstall] && [package isReinstallable]) {
            // Search for the same version of this package in the database
            [actions addObject:@(ZBPackageActionReinstall)];
        }
            
        if (![queue contains:package inQueue:ZBQueueTypeUpgrade] && [[package greaterVersions] count] ) {
            // Only going to explicitly show an "Upgrade" button if there are higher versions available
            [actions addObject:@(ZBPackageActionUpgrade)]; // Select higher verions
        }
            
        if (![queue contains:package inQueue:ZBQueueTypeDowngrade] && [[package lesserVersions] count]) {
            // Only going to explicily show a "Downgrade" button if there are lower verisons available
            [actions addObject:@(ZBPackageActionDowngrade)];
        }
        
        if ([package ignoreUpdates]) {
            // Updates are ignored, show them
            [actions addObject:@(ZBPackageActionShowUpdates)];
        }
        else {
            // Updates are not ignored, give the option to hide them
            [actions addObject:@(ZBPackageActionHideUpdates)];
        }
        [actions addObject:@(ZBPackageActionRemove)]; // Show the remove button regardless
    }
    else {
        if ([[ZBDatabaseManager sharedInstance] packageHasUpdate:package] && [package isEssentialOrRequired]) {
            // If the package has an update available and it is essential or required (a "suggested" package) then you can ignore it
            if ([package ignoreUpdates]) {
                // Updates are ignored, show them
                [actions addObject:@(ZBPackageActionShowUpdates)];
            }
            else {
                // Updates are not ignored, give the option to hide them
                [actions addObject:@(ZBPackageActionHideUpdates)];
            }
        }
        [actions addObject:@(ZBPackageActionInstall)]; // Show "Install" otherwise (could be disabled if its already in the Queue)
    }
    return (NSArray *)actions;
}

+ (NSArray <UITableViewRowAction *> *)rowActionsForPackage:(ZBPackage *)package inViewController:(UITableViewController *)controller atIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *rowActions = [NSMutableArray new];
    
    NSArray *actions = [self actionsForPackage:package];
    for (NSNumber *number in actions) {
        ZBPackageActionType action = number.intValue;
        if (action == ZBPackageActionShowUpdates || action == ZBPackageActionHideUpdates) continue;
        
        NSString *title = [self titleForAction:action useIcon:YES];
        UITableViewRowActionStyle style = action == ZBPackageActionRemove ? UITableViewRowActionStyleDestructive : UITableViewRowActionStyleNormal;
        UITableViewRowAction *rowAction = [UITableViewRowAction rowActionWithStyle:style title:title handler:^(UITableViewRowAction *rowAction, NSIndexPath *indexPath) {
            switch (action) {
                case ZBPackageActionInstall:
                case ZBPackageActionRemove:
                case ZBPackageActionReinstall:
                case ZBPackageActionUpgrade:
                case ZBPackageActionDowngrade:
                default:
                    break;
            }
//            if (q == ZBQueueTypeUpgrade) {
//                [self selectUpgradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent completion:completion];
//            }
//            else if (q == ZBQueueTypeDowngrade) {
//                [self selectDowngradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent completion:completion];
//            }
//            else if (q == ZBQueueTypeClear) {
//                [queue removePackage:package];
//            }
//            else {
//                [queue addPackage:package toQueue:q];
//            }
//
//            if ([vc isKindOfClass:[ZBPackageListTableViewController class]]) {
//                [(ZBPackageListTableViewController *)vc layoutNavigationButtons];
//            }
//
//            if (completion && q != ZBQueueTypeUpgrade && q != ZBQueueTypeDowngrade) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    completion();
//                });
//            }
        }];
        
        [rowAction setBackgroundColor:[self colorForAction:action]];
        [rowActions addObject:rowAction];
    }
    
    return (NSArray *)rowActions;
}

+ (NSArray <UIAlertAction *> *)alertActionsForPackage:(ZBPackage *)package inViewController:(UIViewController *)vc {
    NSMutableArray <UIAlertAction *> *alertActions = [NSMutableArray new];
    
    NSArray *actions = [self actionsForPackage:package];
    for (NSNumber *number in actions) {
        ZBPackageActionType action = number.intValue;
        
        NSString *title = [self titleForAction:action useIcon:NO];
        UIAlertActionStyle style = action == ZBPackageActionRemove ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault;
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:title style:style handler:^(UIAlertAction *alertAction) {
            switch (action) {
                case ZBPackageActionInstall:
                case ZBPackageActionRemove:
                case ZBPackageActionReinstall:
                case ZBPackageActionUpgrade:
                case ZBPackageActionDowngrade:
                case ZBPackageActionShowUpdates:
                case ZBPackageActionHideUpdates:
                    break;
            }
//            if (q == ZBQueueTypeUpgrade) {
//                [self selectUpgradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent completion:completion];
//            }
//            else if (q == ZBQueueTypeDowngrade) {
//                [self selectDowngradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent completion:completion];
//            }
//            else if (q == ZBQueueTypeInstall) {
//                BOOL purchased = [vc respondsToSelector:@selector(purchased)] ? [(ZBPackageDepictionViewController *)vc purchased] : NO;
//                [self installPackage:package purchased:purchased];
//            }
//            else {
//                [queue addPackage:package toQueue:q];
//            }
//
//            if (completion && q != ZBQueueTypeUpgrade && q != ZBQueueTypeDowngrade) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    completion();
//                });
//            }
        }];
        [alertActions addObject:alertAction];
    }
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:NULL];
    [alertActions addObject:cancel];
    
    return (NSArray *)alertActions;
}

+ (NSArray <UIPreviewAction *> *)previewActionsForPackage:(ZBPackage *)package inViewController:(UIViewController *)vc parent:(UIViewController *)parent {
    NSMutableArray <UIPreviewAction *> *previewActions = [NSMutableArray new];
    
    NSArray *actions = [self actionsForPackage:package];
    for (NSNumber *number in actions) {
        ZBPackageActionType action = number.intValue;
        
        NSString *title = [self titleForAction:action useIcon:NO];
        UIPreviewActionStyle style = action == ZBPackageActionRemove ? UIPreviewActionStyleDestructive : UIPreviewActionStyleDefault;
        UIPreviewAction *previewAction = [UIPreviewAction actionWithTitle:title style:style handler:^(UIPreviewAction *previewAction, UIViewController *previewViewController) {
            switch (action) {
                case ZBPackageActionInstall:
                case ZBPackageActionRemove:
                case ZBPackageActionReinstall:
                case ZBPackageActionUpgrade:
                case ZBPackageActionDowngrade:
                case ZBPackageActionShowUpdates:
                case ZBPackageActionHideUpdates:
                    break;
            }
//            if (q == ZBQueueTypeUpgrade) {
//                [self selectUpgradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent completion:completion];
//            }
//            else if (q == ZBQueueTypeDowngrade) {
//                [self selectDowngradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent completion:completion];
//            }
//            else if (q == ZBQueueTypeInstall) {
//                BOOL purchased = [vc respondsToSelector:@selector(purchased)] ? [(ZBPackageDepictionViewController *)vc purchased] : NO;
//                [self installPackage:package purchased:purchased];
//            }
//            else if (q == ZBQueueTypeClear) {
//                [queue removePackage:package];
//            }
//            else {
//                [queue addPackage:package toQueue:q];
//            }
//
//            if (completion && q != ZBQueueTypeUpgrade && q != ZBQueueTypeDowngrade) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    completion();
//                });
//            }
        }];
        
        [previewActions addObject:previewAction];
    }
    
    return (NSArray *)previewActions;
}

+ (NSArray <UIAction *> *)menuElementsForPackage:(ZBPackage *)package atIndexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent API_AVAILABLE(ios(13.0)) {
    NSMutableArray <UIAction *> *UIActions = [NSMutableArray new];
    
    NSArray *actions = [self actionsForPackage:package];
    for (NSNumber *number in actions) {
        ZBPackageActionType action = number.intValue;
        
        NSString *title = [self titleForAction:action useIcon:NO];
        UIImage *image = [self systemImageForAction:action];
        
        UIAction *uiAction = [UIAction actionWithTitle:title image:image identifier:nil handler:^(__kindof UIAction *uiAction) {
            switch (action) {
                case ZBPackageActionInstall:
                case ZBPackageActionRemove:
                case ZBPackageActionReinstall:
                case ZBPackageActionUpgrade:
                case ZBPackageActionDowngrade:
                case ZBPackageActionShowUpdates:
                case ZBPackageActionHideUpdates:
                    break;
            }
        }];
        [UIActions addObject:uiAction];
    }
    
    return (NSArray *)UIActions;
}

+ (void)installPackage:(ZBPackage *)package purchased:(BOOL)purchased {
    if (package == NULL) return;
    if (purchased) {
        package.sileoDownload = YES;
    }
    
    ZBQueue *queue = [ZBQueue sharedQueue];
    [queue addPackage:package toQueue:ZBQueueTypeInstall];
}

+ (void)selectUpgradeableVersionForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent completion:(void (^)(void))completion {
    NSArray *greaterVersions = [package greaterVersions];
    if ([greaterVersions count] > 1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select Version", @"") message:NSLocalizedString(@"Select a version to upgrade to:", @"") preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (ZBPackage *otherPackage in greaterVersions) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:[otherPackage version] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                ZBQueue *queue = [ZBQueue sharedQueue];
                [queue addPackage:otherPackage toQueue:ZBQueueTypeUpgrade];
                
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion();
                    });
                }
            }];
            
            [alert addAction:action];
        }
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        
        if (indexPath) {
            ZBPackageTableViewCell *cell = [((UITableViewController *)vc).tableView cellForRowAtIndexPath:indexPath];
            alert.popoverPresentationController.sourceView = cell;
            alert.popoverPresentationController.sourceRect = cell.bounds;
        } else {
            alert.popoverPresentationController.barButtonItem = vc.navigationItem.rightBarButtonItem;
        }
        
        if (vc.view.window != nil) {
            [vc presentViewController:alert animated:YES completion:nil];
        }
        else {
            [parent presentViewController:alert animated:YES completion:nil];
        }
    }
    else if ([greaterVersions count] == 1) {
        ZBQueue *queue = [ZBQueue sharedQueue];
        [queue addPackage:greaterVersions[0] toQueue:ZBQueueTypeUpgrade];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    }
    else {
        ZBQueue *queue = [ZBQueue sharedQueue];
        [queue addPackage:package toQueue:ZBQueueTypeUpgrade];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    }
}

+ (void)selectDowngradeableVersionForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent completion:(void (^)(void))completion {
    NSArray *lesserVersions = [package lesserVersions];
    if ([lesserVersions count] > 1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select Version", @"") message:NSLocalizedString(@"Select a version to downgrade to:", @"") preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (ZBPackage *otherPackage in lesserVersions) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:[otherPackage version] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                ZBQueue *queue = [ZBQueue sharedQueue];
                [queue addPackage:otherPackage toQueue:ZBQueueTypeDowngrade];
                
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion();
                    });
                }
            }];
            
            [alert addAction:action];
        }
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        
        if (indexPath) {
            ZBPackageTableViewCell *cell = [((UITableViewController *)vc).tableView cellForRowAtIndexPath:indexPath];
            alert.popoverPresentationController.sourceView = cell;
            alert.popoverPresentationController.sourceRect = cell.bounds;
        } else {
            alert.popoverPresentationController.barButtonItem = vc.navigationItem.rightBarButtonItem;
        }
        
        if (vc.view.window != nil) {
            [vc presentViewController:alert animated:YES completion:nil];
        }
        else {
            [parent presentViewController:alert animated:YES completion:nil];
        }
    }
    else if ([lesserVersions count] == 1) {
        ZBQueue *queue = [ZBQueue sharedQueue];
        [queue addPackage:lesserVersions[0] toQueue:ZBQueueTypeDowngrade];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    }
    else {
        ZBQueue *queue = [ZBQueue sharedQueue];
        [queue addPackage:package toQueue:ZBQueueTypeDowngrade];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    }
}

#pragma mark - Displaying Actions to User

+ (UIColor *)colorForAction:(ZBPackageActionType)action {
    switch (action) {
        case ZBPackageActionInstall:
            return [UIColor systemTealColor];
        case ZBPackageActionRemove:
            return [UIColor systemPinkColor];
        case ZBPackageActionReinstall:
            return [UIColor systemOrangeColor];
        case ZBPackageActionUpgrade:
            return [UIColor systemBlueColor];
        case ZBPackageActionDowngrade:
            return [UIColor systemPurpleColor];
        default:
            return nil;
    }
}

+ (UIImage *)systemImageForAction:(ZBPackageActionType)action API_AVAILABLE(ios(13.0)) {
    NSString *imageName;
    switch (action) {
        case ZBPackageActionInstall:
            imageName = @"icloud.and.arrow.down";
            break;
        case ZBPackageActionRemove:
            imageName = @"trash";
            break;
        case ZBPackageActionReinstall:
            imageName = @"arrow.clockwise";
            break;
        case ZBPackageActionUpgrade:
            imageName = @"arrow.up";
            break;
        case ZBPackageActionDowngrade:
            imageName = @"arrow.down";
            break;
        default:
            break;
    }
    
    UIImageSymbolConfiguration *imgConfig = [UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightHeavy];
    return [UIImage systemImageNamed:imageName withConfiguration:imgConfig];
}

+ (NSString *)titleForAction:(ZBPackageActionType)action useIcon:(BOOL)icon {
    BOOL useIcon = icon && [ZBDevice useIcon];
    
    switch (action) {
        case ZBPackageActionInstall:
            return useIcon ? @"↓" : NSLocalizedString(@"Install", @"");
        case ZBPackageActionRemove:
            return useIcon ? @"╳" : NSLocalizedString(@"Remove", @"");
        case ZBPackageActionReinstall:
            return useIcon ? @"↺" : NSLocalizedString(@"Reinstall", @"");
        case ZBPackageActionUpgrade:
            return useIcon ? @"↑" : NSLocalizedString(@"Upgrade", @"");
        case ZBPackageActionDowngrade:
            return useIcon ? @"⇵" : NSLocalizedString(@"Downgrade", @"");
        case ZBPackageActionShowUpdates:
            return NSLocalizedString(@"Install", @"");
        case ZBPackageActionHideUpdates:
            return NSLocalizedString(@"Remove", @"");
        default:
            break;
    }
    return @"Undefined";
}

+ (NSString *)buttonTitleForActions:(NSArray *)actions {
    if ([actions count] > 1) {
        return NSLocalizedString(@"Modify", @"");
    }
    else if ((ZBPackageActionType)actions[0] == ZBPackageActionInstall) {
        return NSLocalizedString(@"Install", @"");
    }
    else {
        return NSLocalizedString(@"Remove", @"");
    }
}

@end
