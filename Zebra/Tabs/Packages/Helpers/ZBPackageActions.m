//
//  ZBPackageActions.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 13/5/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageActions.h"
#import "ZBPackage.h"

#import <ZBDevice.h>
#import <ZBAppDelegate.h>
#import <Sources/Helpers/ZBSource.h>
#import <Packages/Views/ZBPackageTableViewCell.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import <Queue/ZBQueue.h>
#import <UIColor+GlobalColors.h>
#import <Packages/Controllers/ZBPackageListTableViewController.h>
#import <Extensions/UIAlertController+Show.h>
#import <JSONParsing/ZBPurchaseInfo.h>

@implementation ZBPackageActions

#pragma mark - Package Actions

+ (void)performAction:(ZBPackageActionType)action forPackage:(ZBPackage *)package {
    if (!package) return;
    if (action < ZBPackageActionInstall || action > ZBPackageActionHideUpdates) return;
    
    switch (action) {
        case ZBPackageActionInstall:
            [self install:package];
            break;
        case ZBPackageActionRemove:
            [self remove:package];
            break;
        case ZBPackageActionReinstall:
            [self reinstall:package];
            break;
        case ZBPackageActionUpgrade:
            [self upgrade:package];
            break;
        case ZBPackageActionDowngrade:
            [self downgrade:package];
            break;
        case ZBPackageActionShowUpdates:
            [self showUpdatesFor:package];
            break;
        case ZBPackageActionHideUpdates:
            [self hideUpdatesFor:package];
            break;
    }
}

+ (void)install:(ZBPackage *)package {

}

+ (void)remove:(ZBPackage *)package {
    
}

+ (void)reinstall:(ZBPackage *)package {
    
}

+ (void)upgrade:(ZBPackage *)package {
    
}

+ (void)upgrade:(ZBPackage *)package toVersion:(NSString *)version {
    
}

+ (void)downgrade:(ZBPackage *)package {
    
}

+ (void)downgrade:(ZBPackage *)package toVersion:(NSString *)version {
    
}

+ (void)showUpdatesFor:(ZBPackage *)package {
    
}

+ (void)hideUpdatesFor:(ZBPackage *)package {
    
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

#pragma mark - Display Actions

+ (void)barButtonItemForPackage:(ZBPackage *)package completion:(void (^)(UIBarButtonItem *barButton))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        UIBarButtonItemActionHandler handler = ^{
            NSArray <NSNumber *> *actions = [package possibleActions];
            if ([actions count] > 1) {
                UIAlertController *selectAction = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@)", package.name, package.version] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                
                for (UIAlertAction *action in [ZBPackageActions alertActionsForPackage:package]) {
                    [selectAction addAction:action];
                }
                
                [selectAction show];
            }
            else {
                ZBPackageActionType action = actions[0].intValue;
                [self performAction:action forPackage:package];
            }
        };
        
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:[self buttonTitleForPackage:package] style:UIBarButtonItemStylePlain actionHandler:handler];
        if ([package mightRequirePayment]) {
            [package purchaseInfo:^(ZBPurchaseInfo * _Nonnull info) {
                if (info) { // Package does have purchase info
                    if (!info.purchased && ![package isInstalled:NO]) { // If the user has not purchased the package
                        UIBarButtonItem *purchaseButton = [[UIBarButtonItem alloc] initWithTitle:info.price style:UIBarButtonItemStylePlain actionHandler:^{
                            [self performAction:ZBPackageActionInstall forPackage:package];
                        }];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(purchaseButton);
                        });
                        return;
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(button);
                });
                return;
            }];
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(button);
        });
        return;
    });
}

+ (NSArray <UITableViewRowAction *> *)rowActionsForPackage:(ZBPackage *)package {
    NSMutableArray *rowActions = [NSMutableArray new];
    
    NSArray *actions = [package possibleActions];
    for (NSNumber *number in actions) {
        ZBPackageActionType action = number.intValue;
        if (action == ZBPackageActionShowUpdates || action == ZBPackageActionHideUpdates) continue;
        
        NSString *title = [self titleForAction:action useIcon:YES];
        UITableViewRowActionStyle style = action == ZBPackageActionRemove ? UITableViewRowActionStyleDestructive : UITableViewRowActionStyleNormal;
        UITableViewRowAction *rowAction = [UITableViewRowAction rowActionWithStyle:style title:title handler:^(UITableViewRowAction *rowAction, NSIndexPath *indexPath) {
            [self performAction:action forPackage:package];
        }];
        
        [rowAction setBackgroundColor:[self colorForAction:action]];
        [rowActions addObject:rowAction];
    }
    
    return (NSArray *)rowActions;
}

+ (NSArray <UIAlertAction *> *)alertActionsForPackage:(ZBPackage *)package {
    NSMutableArray <UIAlertAction *> *alertActions = [NSMutableArray new];
    
    NSArray *actions = [package possibleActions];
    for (NSNumber *number in actions) {
        ZBPackageActionType action = number.intValue;
        
        NSString *title = [self titleForAction:action useIcon:NO];
        UIAlertActionStyle style = action == ZBPackageActionRemove ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault;
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:title style:style handler:^(UIAlertAction *alertAction) {
            [self performAction:action forPackage:package];
        }];
        [alertActions addObject:alertAction];
    }
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:NULL];
    [alertActions addObject:cancel];
    
    return (NSArray *)alertActions;
}

+ (NSArray <UIPreviewAction *> *)previewActionsForPackage:(ZBPackage *)package {
    NSMutableArray <UIPreviewAction *> *previewActions = [NSMutableArray new];
    
    NSArray *actions = [package possibleActions];
    for (NSNumber *number in actions) {
        ZBPackageActionType action = number.intValue;
        
        NSString *title = [self titleForAction:action useIcon:NO];
        UIPreviewActionStyle style = action == ZBPackageActionRemove ? UIPreviewActionStyleDestructive : UIPreviewActionStyleDefault;
        UIPreviewAction *previewAction = [UIPreviewAction actionWithTitle:title style:style handler:^(UIPreviewAction *previewAction, UIViewController *previewViewController) {
            [self performAction:action forPackage:package];
        }];
        
        [previewActions addObject:previewAction];
    }
    
    return (NSArray *)previewActions;
}

+ (NSArray <UIAction *> *)menuElementsForPackage:(ZBPackage *)package API_AVAILABLE(ios(13.0)) {
    NSMutableArray <UIAction *> *uiActions = [NSMutableArray new];
    
    NSArray *actions = [package possibleActions];
    for (NSNumber *number in actions) {
        ZBPackageActionType action = number.intValue;
        
        NSString *title = [self titleForAction:action useIcon:NO];
        UIImage *image = [self systemImageForAction:action];
        
        UIAction *uiAction = [UIAction actionWithTitle:title image:image identifier:nil handler:^(__kindof UIAction *uiAction) {
            [self performAction:action forPackage:package];
        }];
        [uiActions addObject:uiAction];
    }
    
    return (NSArray *)uiActions;
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
            return NSLocalizedString(@"Show Updates", @"");
        case ZBPackageActionHideUpdates:
            return NSLocalizedString(@"Hide Updates", @"");
        default:
            break;
    }
    return @"Undefined";
}

+ (NSString *)buttonTitleForPackage:(ZBPackage *)package {
    NSArray <NSNumber *> *actions = [package possibleActions];
    if ([actions count] > 1) {
        return NSLocalizedString(@"Modify", @"");
    }
    else {
        ZBPackageActionType action = actions[0].intValue;
        return [self titleForAction:action useIcon:NO];
    }
}

@end
