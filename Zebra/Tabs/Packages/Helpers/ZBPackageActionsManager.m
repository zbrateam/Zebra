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
#import <UIColor+Zebra.h>
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
                    [self selectUpgradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent];
                }
                else if (q == ZBQueueTypeDowngrade) {
                    [self selectDowngradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent];
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
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion();
                    });
                }
            };
        }
        case 1: { // previewAction
            return ^(void) {
                if (q == ZBQueueTypeUpgrade) {
                    [self selectUpgradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent];
                }
                else if (q == ZBQueueTypeDowngrade) {
                    [self selectDowngradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent];
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
            };
        }
        case 2: { // alertAction
            return ^(void) {
                if (q == ZBQueueTypeUpgrade) {
                    [self selectUpgradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent];
                }
                else if (q == ZBQueueTypeDowngrade) {
                    [self selectDowngradeableVersionForPackage:package indexPath:indexPath viewController:vc parent:parent];
                }
                else if (q == ZBQueueTypeInstall) {
                    BOOL purchased = [vc respondsToSelector:@selector(purchased)] ? [(ZBPackageDepictionViewController *)vc purchased] : NO;
                    [self installPackage:package purchased:purchased];
                    
                    [[ZBAppDelegate tabBarController] openQueue:YES];
                }
                else if (q == ZBQueueTypeClear) {
                    [[ZBAppDelegate tabBarController] openQueue:YES];
                }
                else {
                    [queue addPackage:package toQueue:q];
                    [[ZBAppDelegate tabBarController] openQueue:YES];
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
            void (^handler)(void) = [self getHandler:type package:package indexPath:indexPath queue:q to:queue viewController:vc parent:parent completion:completion];
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

+ (NSMutableArray <UIAlertAction *> *)alertActionsForPackage:(ZBPackage *)package viewController:(UIViewController *)vc parent:(UIViewController *)parent {
    NSMutableArray *actions = [self actions:2 forPackage:package indexPath:nil viewController:vc parent:parent completion:NULL];
    
    if ([package ignoreUpdates]) {
        UIAlertAction *unignore = [UIAlertAction actionWithTitle:@"Show Updates" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [package setIgnoreUpdates:NO];
        }];
        
        [actions addObject:unignore];
    } else {
        UIAlertAction *ignore = [UIAlertAction actionWithTitle:@"Ignore Updates" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [package setIgnoreUpdates:YES];
        }];
        
        [actions addObject:ignore];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL];
    [actions addObject:cancel];
    
    return actions;
}

+ (void)installPackage:(ZBPackage *)package purchased:(BOOL)purchased {
    if (purchased) {
        package.sileoDownload = YES;
    }
    
    ZBQueue *queue = [ZBQueue sharedQueue];
    [queue addPackage:package toQueue:ZBQueueTypeInstall];
}

+ (void)selectUpgradeableVersionForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent {
    NSArray *greaterVersions = [package greaterVersions];
    if ([greaterVersions count] > 1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Select Version" message:@"Select a version to upgrade to" preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (ZBPackage *otherPackage in greaterVersions) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:[otherPackage version] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                ZBQueue *queue = [ZBQueue sharedQueue];
                [queue addPackage:otherPackage toQueue:ZBQueueTypeUpgrade];
                [[ZBAppDelegate tabBarController] openQueue:YES];
            }];
            
            [alert addAction:action];
        }
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL];
        [alert addAction:cancel];
        
        if (indexPath) {
            ZBPackageTableViewCell *cell = [((UITableViewController *)vc).tableView cellForRowAtIndexPath:indexPath];
            alert.popoverPresentationController.sourceView = cell;
            alert.popoverPresentationController.sourceRect = cell.bounds;
        } else {
            alert.popoverPresentationController.barButtonItem = vc.navigationItem.rightBarButtonItem;
        }
        
        [vc presentViewController:alert animated:YES completion:nil];
    }
    else if ([greaterVersions count] == 1) {
        ZBQueue *queue = [ZBQueue sharedQueue];
        [queue addPackage:greaterVersions[0] toQueue:ZBQueueTypeUpgrade];
        [[ZBAppDelegate tabBarController] openQueue:YES];
    }
    else {
        ZBQueue *queue = [ZBQueue sharedQueue];
        [queue addPackage:package toQueue:ZBQueueTypeUpgrade];
        [[ZBAppDelegate tabBarController] openQueue:YES];
    }
}

+ (void)selectDowngradeableVersionForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent {
    NSArray *lesserVersions = [package lesserVersions];
    if ([lesserVersions count] > 1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Select Version" message:@"Select a version to downgrade to" preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (ZBPackage *otherPackage in [package lesserVersions]) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:[otherPackage version] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                ZBQueue *queue = [ZBQueue sharedQueue];
                [queue addPackage:otherPackage toQueue:ZBQueueTypeDowngrade];
                [[ZBAppDelegate tabBarController] openQueue:YES];
            }];
            
            [alert addAction:action];
        }
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL];
        [alert addAction:cancel];
        
        if (indexPath) {
            ZBPackageTableViewCell *cell = [((UITableViewController *)vc).tableView cellForRowAtIndexPath:indexPath];
            alert.popoverPresentationController.sourceView = cell;
            alert.popoverPresentationController.sourceRect = cell.bounds;
        } else {
            alert.popoverPresentationController.barButtonItem = vc.navigationItem.rightBarButtonItem;
        }
        
        [vc presentViewController:alert animated:YES completion:nil];
    }
    else if ([lesserVersions count] == 1) {
        ZBQueue *queue = [ZBQueue sharedQueue];
        [queue addPackage:lesserVersions[0] toQueue:ZBQueueTypeDowngrade];
        [[ZBAppDelegate tabBarController] openQueue:YES];
    }
    else {
        ZBQueue *queue = [ZBQueue sharedQueue];
        [queue addPackage:package toQueue:ZBQueueTypeDowngrade];
        [[ZBAppDelegate tabBarController] openQueue:YES];
    }
}

@end
