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
                if (q == ZBQueueTypeSelectable) {
                    [self selectVersionForPackage:package indexPath:indexPath viewController:vc parent:parent];
                }
                else {
                    [queue addPackage:package toQueue:q];
                }
                
                if ([vc respondsToSelector:@selector(configureNavigationButtons)]) {
                    [(ZBPackageListTableViewController *)vc configureNavigationButtons];
                }
                if (completion) {
                    completion();
                }
            };
        }
        case 1: { // previewAction
            return ^(void) {
                if (q == ZBQueueTypeInstall) {
                    BOOL purchased = [vc respondsToSelector:@selector(purchased)] ? [(ZBPackageDepictionViewController *)vc purchased] : NO;
                    [self installPackage:package purchased:purchased];
                }
                else if (q == ZBQueueTypeSelectable) {
                    [self selectVersionForPackage:package indexPath:nil viewController:vc parent:parent];
                }
                else {
                    [queue addPackage:package toQueue:q];
                }
            };
        }
        case 2: { // alertAction
            return ^(void) {
                if (q == ZBQueueTypeInstall) {
                    BOOL purchased = [vc respondsToSelector:@selector(purchased)] ? [(ZBPackageDepictionViewController *)vc purchased] : NO;
                    [self installPackage:package purchased:purchased];
                    [self presentQueue:vc parent:parent];
                }
                else if (q == ZBQueueTypeSelectable) {
                    [self selectVersionForPackage:package indexPath:nil viewController:vc parent:parent];
                }
                else {
                    [queue addPackage:package toQueue:q];
                    [self presentQueue:vc parent:parent];
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
    ZBQueue *queue = [ZBQueue sharedInstance];
    
    for (ZBQueueType q = ZBQueueTypeInstall; q <= ZBQueueTypeSelectable; q <<= 1) {
        if ([self canHaveAction:possibleActions forPackage:package queue:q]) {
            NSString *title = [queue queueToKey:q];
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
    NSMutableArray *actions = [self actions:2 forPackage:package indexPath:nil viewController:vc parent:parent completion:NULL];;
    
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

+ (void)selectVersionForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Select Version: %@ (%@)", [package name], [package version]] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (ZBPackage *otherPackage in [package otherVersions]) {
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:[otherPackage version] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ZBQueue *queue = [ZBQueue sharedInstance];
            [queue addPackage:otherPackage toQueue:ZBQueueTypeInstall replace:package];
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
