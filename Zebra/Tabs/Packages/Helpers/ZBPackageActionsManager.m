//
//  ZBPackageActionsManager.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 13/5/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageActionsManager.h"
#import <ZBAppDelegate.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Views/ZBPackageTableViewCell.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import <Queue/ZBQueue.h>
#import <UIColor+GlobalColors.h>
#import <Packages/Controllers/ZBPackageListTableViewController.h>

@implementation ZBPackageActionsManager

+ (BOOL)isActionAllowed:(NSUInteger)possibleAction forPackage:(ZBPackage *)package queue:(ZBQueueType)q {
    BOOL inQueue = [[ZBQueue sharedQueue] contains:package inQueue:q];
    if (inQueue && q == ZBQueueTypeClear)
        return YES;
    BOOL allowed = possibleAction & q;
    return allowed && !inQueue;
}

+ (UIColor *)colorForAction:(ZBQueueType)queue {
    switch (queue) {
        case ZBQueueTypeInstall:
            return [UIColor systemTealColor];
        case ZBQueueTypeRemove:
            return [UIColor systemPinkColor];
        case ZBQueueTypeReinstall:
            return [UIColor systemOrangeColor];
        case ZBQueueTypeUpgrade:
            return [UIColor systemBlueColor];
        case ZBQueueTypeDowngrade:
            return [UIColor systemPurpleColor];
        case ZBQueueTypeDependency:
            return [UIColor systemTealColor];
        case ZBQueueTypeConflict:
            return [UIColor systemPinkColor];
        default:
            return nil;
    }
}

+ (id)getAction:(int)type title:(NSString *)title queue:(ZBQueueType)queue handler:(void (^)(void))handler {
    id action = nil;
    switch (type) {
        case 0: { // rowAction
            action = [UITableViewRowAction rowActionWithStyle:queue == ZBQueueTypeRemove ? UITableViewRowActionStyleDestructive : UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                handler();
            }];
            UIColor *color = [self colorForAction:queue];
            if (color) {
                ((UIView *)action).backgroundColor = color;
            }
            break;
        }
        case 1: { // previewAction
            action = [UIPreviewAction actionWithTitle:title style:queue == ZBQueueTypeRemove ? UIPreviewActionStyleDestructive : UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                handler();
            }];
            break;
        }
        case 2: { // alertAction
            action = [UIAlertAction actionWithTitle:title style:queue == ZBQueueTypeRemove ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                handler();
            }];
            break;
        }
        case 3: { // contextMenuAction
            if (@available(iOS 13.0, *)) {
                NSString *imageName;
                switch (queue) {
                    case ZBQueueTypeReinstall:
                        imageName = @"arrow.clockwise";
                        break;
                    case ZBQueueTypeUpgrade:
                        imageName = @"arrow.up";
                        break;
                    case ZBQueueTypeRemove:
                        imageName = @"trash";
                        break;
                    case ZBQueueTypeInstall:
                        imageName = @"icloud.and.arrow.down";
                        break;
                    case ZBQueueTypeDowngrade:
                        imageName = @"arrow.down";
                        break;
                        
                    default:
                        break;
                }
                UIImageSymbolConfiguration *imgConfig = [UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightHeavy];
                UIImage *image = [UIImage systemImageNamed:imageName withConfiguration:imgConfig];
                
                UIAction *uiAction = [UIAction actionWithTitle:title image:image identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    handler();
                }];
                
                if (queue == ZBQueueTypeRemove) {
                    uiAction.attributes = UIMenuElementAttributesDestructive;
                }
                
                action = uiAction;
            }
            break;
        }
        default:
            break;
    }
    
    return action;
}

+ (void (^)(void))getHandler:(int)type package:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath queue:(ZBQueueType)q to:(ZBQueue *)queue viewController:(UIViewController *)vc parent:(UIViewController *)parent completion:(void (^)(void))completion {
    switch (type) {
        case 0: { // rowAction
            return ^(void) {
                if (q == ZBQueueTypeUpgrade) {
                    [self selectUpgradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent completion:completion];
                }
                else if (q == ZBQueueTypeDowngrade) {
                    [self selectDowngradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent completion:completion];
                }
                else if (q == ZBQueueTypeClear) {
                    [queue removePackage:package];
                }
                else {
                    [queue addPackage:package toQueue:q]; 
                }

                if ([vc isKindOfClass:[ZBPackageListTableViewController class]]) {
                    [(ZBPackageListTableViewController *)vc layoutNavigationButtons];
                }
                
                if (completion && q != ZBQueueTypeUpgrade && q != ZBQueueTypeDowngrade) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion();
                    });
                }
            };
        }
        case 1: { // previewAction
            return ^(void) {
                if (q == ZBQueueTypeUpgrade) {
                    [self selectUpgradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent completion:completion];
                }
                else if (q == ZBQueueTypeDowngrade) {
                    [self selectDowngradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent completion:completion];
                }
                else if (q == ZBQueueTypeInstall) {
                    BOOL purchased = [vc respondsToSelector:@selector(purchased)] ? [(ZBPackageDepictionViewController *)vc purchased] : NO;
                    [self installPackage:package purchased:purchased];
                }
                else if (q == ZBQueueTypeClear) {
                    [queue removePackage:package];
                }
                else {
                    [queue addPackage:package toQueue:q];
                }
                
                if (completion && q != ZBQueueTypeUpgrade && q != ZBQueueTypeDowngrade) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion();
                    });
                }
            };
        }
        case 2: { // alertAction
            return ^(void) {
                if (q == ZBQueueTypeUpgrade) {
                    [self selectUpgradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent completion:completion];
                }
                else if (q == ZBQueueTypeDowngrade) {
                    [self selectDowngradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent completion:completion];
                }
                else if (q == ZBQueueTypeInstall) {
                    BOOL purchased = [vc respondsToSelector:@selector(purchased)] ? [(ZBPackageDepictionViewController *)vc purchased] : NO;
                    [self installPackage:package purchased:purchased];
                }
                else {
                    [queue addPackage:package toQueue:q];
                }
                
                if (completion && q != ZBQueueTypeUpgrade && q != ZBQueueTypeDowngrade) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion();
                    });
                }
            };
        }
        default:
            return NULL;
    }
}

+ (NSMutableArray *)actions:(int)type forPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent completion:(void (^)(void))completion {
    NSMutableArray *actions = [NSMutableArray array];
    NSUInteger possibleActions = [package possibleActions];
    ZBQueue *queue = [ZBQueue sharedQueue];
    
    for (ZBQueueType q = ZBQueueTypeInstall; q <= ZBQueueTypeDowngrade; q <<= 1) {
        if ([self isActionAllowed:possibleActions forPackage:package queue:q]) {
            NSString *title = [queue displayableNameForQueueType:q useIcon:(type == 0)];
            void (^handler)(void) = [self getHandler:(type == 3 ? 1 : type) package:package indexPath:indexPath queue:q to:queue viewController:vc parent:parent completion:completion];
            id action = [self getAction:type title:title queue:q handler:handler];
            [actions addObject:action];
        }
    }
    
    return actions;
}

+ (NSMutableArray <UITableViewRowAction *> *)rowActionsForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UITableViewController *)vc parent:(UIViewController *)parent completion:(void (^)(void))completion {
    ZBPackageListTableViewController *controller = (ZBPackageListTableViewController *)vc;
    return [self actions:0 forPackage:package indexPath:indexPath viewController:controller parent:parent completion:completion];
}

+ (NSMutableArray <UIPreviewAction *> *)previewActionsForPackage:(ZBPackage *)package viewController:(UIViewController *)vc parent:(UIViewController *)parent {
    return [self actions:1 forPackage:package indexPath:nil viewController:vc parent:parent completion:NULL];
}

+ (NSMutableArray <UIMenuElement *> *)contextMenuActionsForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent  API_AVAILABLE(ios(13.0)){
    return [self actions:3 forPackage:package indexPath:indexPath viewController:vc parent:parent completion:NULL];
}

+ (NSMutableArray <UIAlertAction *> *)alertActionsForPackage:(ZBPackage *)package viewController:(UIViewController *)vc parent:(UIViewController *)parent {
    NSMutableArray *actions = [self actions:2 forPackage:package indexPath:nil viewController:vc parent:parent completion:NULL];
    
    if ([package ignoreUpdates]) {
        UIAlertAction *unignore = [UIAlertAction actionWithTitle:NSLocalizedString(@"Show Updates", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [package setIgnoreUpdates:NO];
        }];
        
        [actions addObject:unignore];
    } else {
        UIAlertAction *ignore = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ignore Updates", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [package setIgnoreUpdates:YES];
        }];
        
        [actions addObject:ignore];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:NULL];
    [actions addObject:cancel];
    
    return actions;
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

@end
