//
//  ZBPackageActions.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 13/5/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageActions.h"

#import "Zebra-Swift.h"
#import "ZBAppDelegate.h"
#import <Headers/UIAlertController+Private.h>
#import <UI/Packages/Views/Cells/ZBPackageTableViewCell.h>
#import <UI/Packages/ZBPackageViewController.h>
#import <UI/Packages/ZBPackageListViewController.h>
#import <Extensions/UIAlertController+Zebra.h>
#import <JSONParsing/ZBPurchaseInfo.h>
#import <UI/ZBTabBarController.h>

#import <Model/PLPackage+Zebra.h>
#import <Plains/Queue/PLQueue.h>

@implementation ZBPackageActions

#pragma mark - Package Actions

+ (void)performExtraAction:(ZBPackageExtraActionType)action forPackage:(PLPackage *)package completion:(void (^)(ZBPackageExtraActionType action))completion {
    switch (action) {
        case ZBPackageExtraActionShowUpdates:
            package.held = NO;
            if (completion) completion(action);
            break;
        case ZBPackageExtraActionHideUpdates:
            package.held = YES;
            if (completion) completion(action);
            break;
//        case ZBPackageExtraActionAddFavorite:
//            [self addFavorite:package];
//            if (completion) completion(action);
//            break;
//        case ZBPackageExtraActionRemoveFavorite:
//            [self removeFavorite:package];
//            if (completion) completion(action);
//            break;
//        case ZBPackageExtraActionBlockAuthor:
//            [self blockAuthorOf:package];
//            if (completion) completion(action);
//            break;
//        case ZBPackageExtraActionUnblockAuthor:
//            [self unblockAuthorOf:package];
//            if (completion) completion(action);
//            break;
//        case ZBPackageExtraActionShare:
//            if (completion) completion(action);
//            break;
    }
}

+ (void)performAction:(ZBPackageActionType)action forPackages:(NSArray <ZBPackage *> *)packages completion:(void (^)(void))completion {
//    dispatch_group_t group = dispatch_group_create();
//
//    for (ZBPackage *package in packages) {
//        dispatch_group_enter(group);
//        [self performAction:action forPackage:package completion:^{
//            dispatch_group_leave(group);
//        }];
//    }
//
//    dispatch_group_notify(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
//        if (completion) completion();
//    });
}

+ (void)performAction:(ZBPackageActionType)action forPackage:(PLPackage *)package controller:(UIViewController *)controller sender:(UIView *)sender completion:(void (^)(void))completion {
    [self performAction:action forPackage:package controller:controller sender:sender checkPayment:YES completion:completion];
}

+ (void)performAction:(ZBPackageActionType)action forPackage:(PLPackage *)package controller:(UIViewController *)controller sender:(UIView *)sender checkPayment:(BOOL)checkPayment completion:(void (^)(void))completion {
    if (!package) return;
    if (action < ZBPackageActionInstall || action > ZBPackageActionSelectVersion) return;
    
//    if (checkPayment && action != ZBPackageActionRemove && [package mightRequirePayment]) { // No need to check for authentication on show/hide updates
//        [package purchaseInfo:^(ZBPurchaseInfo * _Nonnull info) {
//            if (info && info.purchased && info.available) { // Either the package does not require authorization OR the package is purchased and available.
//                [self performAction:action forPackage:package checkPayment:NO completion:completion];
//            }
//            else if (!info.available) { // Package isn't available.
//                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Package not available", @"") message:NSLocalizedString(@"This package is no longer for sale and cannot be downloaded.", @"") preferredStyle:UIAlertControllerStyleAlert];
//
//                UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil];
//                [alert addAction:ok];
//
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [alert show];
//                });
//            }
//            else if (!info.purchased) { // Package isn't purchased, purchase it.
//                [package purchase:^(BOOL success, NSError * _Nullable error) {
//                    if (success && !error) {
//                        [self performAction:action forPackage:package completion:completion];
//                    }
//                    else if (error) {
//                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to complete purchase", @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
//
//                        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil];
//                        [alert addAction:ok];
//
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            [alert show];
//                        });
//                    }
//                    else if (!info.purchased) { // Package isn't purchased, purchase it.
//                        [package purchase:^(BOOL success, NSError * _Nullable error) {
//                            if (success && !error) {
//                                [self performAction:action forPackage:package checkPayment:NO completion:completion];
//                            }
//                            else if (error) {
//                                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to complete purchase", @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
//
//                                UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil];
//                                [alert addAction:ok];
//
//                                dispatch_async(dispatch_get_main_queue(), ^{
//                                    [alert show];
//                                });
//                            }
//                        }];
//                    }
//                    else { // Fall-through, this will not check for payment info again.
//                        [self performAction:action forPackage:package checkPayment:NO completion:completion];
//                    }
//                }];
//            }
//            else { // Fall-through, this will not check for payment info again.
//                [self performAction:action forPackage:package checkPayment:NO completion:completion];
//            }
//        }];
//        return;
//    }
    
    switch (action) {
        case ZBPackageActionInstall: {
            if (package.allVersions.count > 1 && ![ZBSettings alwaysInstallLatest]) {
                [self choose:package controller:controller sender:sender completion:completion];
            } else {
                [self install:package completion:completion];
            }
            break;
        }
        case ZBPackageActionRemove:
            [self remove:package completion:completion];
            break;
        case ZBPackageActionReinstall:
            [self reinstall:package completion:completion];
            break;
        case ZBPackageActionUpgrade:
            [self upgrade:package controller:controller sender:sender completion:completion];
            break;
        case ZBPackageActionDowngrade:
            [self downgrade:package controller:controller sender:sender completion:completion];
            break;
//        case ZBPackageActionSelectVersion:
//            [self choose:package completion:completion];
//            break;
    }
}

+ (void)install:(PLPackage *)package completion:(void (^)(void))completion {
    [[PLQueue sharedInstance] addPackage:package toQueue:PLQueueInstall];
    if (completion) completion();
}

+ (void)remove:(PLPackage *)package completion:(void (^)(void))completion {
    [[PLQueue sharedInstance] addPackage:package toQueue:PLQueueRemove];
    if (completion) completion();
}

+ (void)reinstall:(PLPackage *)package completion:(void (^)(void))completion {
    [[PLQueue sharedInstance] addPackage:package toQueue:PLQueueReinstall];
    if (completion) completion();
}

+ (void)choose:(PLPackage *)package controller:(UIViewController *)controller sender:(UIView *)sender completion:(void (^)(void))completion {
    NSArray <PLPackage *> *allVersions = [package allVersions];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select Version", @"") message:NSLocalizedString(@"Select a version to install:", @"") preferredStyle:UIAlertControllerStyleActionSheet];

    for (PLPackage *otherVersion in allVersions) {
        NSString *title = otherVersion.version;
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[PLQueue sharedInstance] addPackage:otherVersion toQueue:PLQueueDowngrade];

            if (completion) completion();
        }];

        [alert addAction:action];
    }

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];

    alert.popoverPresentationController.sourceView = sender;
    [controller presentViewController:alert animated:YES completion:nil];
}

+ (void)upgrade:(PLPackage *)package controller:(UIViewController *)controller sender:(UIView *)sender completion:(void (^)(void))completion {
//    ZBPackage *installedPackage = [[ZBPackageManager sharedInstance] installedInstanceOfPackage:package];
//    NSArray <NSString *> *greaterVersions = installedPackage.greaterVersions;
//    if (greaterVersions.count > 1) {
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select Version", @"") message:NSLocalizedString(@"Select a version to upgrade to:", @"") preferredStyle:[self alertControllerStyle]];
//
//        NSCountedSet *versionStrings = [[NSCountedSet alloc] initWithArray:greaterVersions];
//        NSOrderedSet *deduplicatedVersions = [[NSOrderedSet alloc] initWithArray:greaterVersions];
//        for (NSString *otherVersion in deduplicatedVersions) {
//            NSString *title = otherVersion;
//            UIAlertAction *action;
//            if ([versionStrings countForObject:otherVersion] > 1) {
//                action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                    NSArray <ZBPackage *> *otherPackages = [[ZBPackageManager sharedInstance] allRemoteInstancesOfPackage:package withVersion:otherVersion];
//
//                    UIAlertController *sourceAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select Source", @"") message:NSLocalizedString(@"Select a source to upgrade the package from:", @"") preferredStyle:[self alertControllerStyle]];
//
//                    for (ZBPackage *otherPackage in otherPackages) {
//                        UIAlertAction *sourceAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@", otherPackage.source.label] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                            otherPackage.requiresAuthorization = package.requiresAuthorization;
////                            [[ZBQueue sharedQueue] addPackage:otherPackage toQueue:ZBQueueTypeUpgrade];
//
//                            if (completion) completion();
//                        }];
//                        [sourceAlert addAction:sourceAction];
//                    }
//                    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];
//                    [sourceAlert addAction:cancel];
//
//                    [sourceAlert show];
//                }];
//            } else {
//                action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                    ZBPackage *otherPackage = [[ZBPackageManager sharedInstance] remoteInstanceOfPackage:package withVersion:otherVersion];
//                    otherPackage.requiresAuthorization = package.requiresAuthorization;
////                    [[ZBQueue sharedQueue] addPackage:otherPackage toQueue:ZBQueueTypeUpgrade];
//
//                    if (completion) completion();
//                }];
//            }
//
//            [alert addAction:action];
//        }
//
//        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];
//        [alert addAction:cancel];
//
//        [alert show];
//    }
//    else if (greaterVersions.count == 1) {
//        ZBPackage *upgrade = [[ZBPackageManager sharedInstance] remoteInstanceOfPackage:package withVersion:greaterVersions.firstObject];
////        [[ZBQueue sharedQueue] addPackage:upgrade toQueue:ZBQueueTypeUpgrade];
//
//        if (completion) completion();
//    } else {
        [[PLQueue sharedInstance] addPackage:package toQueue:PLQueueUpgrade];
        
        if (completion) completion();
//    }
}

+ (void)downgrade:(PLPackage *)package controller:(UIViewController *)controller sender:(UIView *)sender completion:(void (^)(void))completion {
    NSArray <PLPackage *> *lesserVersions = [package lesserVersions];
    if (lesserVersions.count > 1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select Version", @"") message:NSLocalizedString(@"Select a version to downgrade to:", @"") preferredStyle:UIAlertControllerStyleActionSheet];

        for (PLPackage *otherVersion in lesserVersions) {
            NSString *title = otherVersion.version;
            UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[PLQueue sharedInstance] addPackage:otherVersion toQueue:PLQueueDowngrade];

                if (completion) completion();
            }];

            [alert addAction:action];
        }

        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];

        alert.popoverPresentationController.sourceView = sender;
        [controller presentViewController:alert animated:YES completion:nil];
    } else if (lesserVersions.count == 1) {
        [[PLQueue sharedInstance] addPackage:lesserVersions[0] toQueue:PLQueueDowngrade];
        if (completion) completion();
    }
}

//+ (void)addFavorite:(ZBPackage *)package {
//    NSMutableArray *favorites = [[ZBSettings favoritePackages] mutableCopy];
//    BOOL isFavorited = [favorites containsObject:package.identifier];
//    if (!isFavorited) {
//        [favorites addObject:package.identifier];
//    }
//    [ZBSettings setFavoritePackages:favorites];
//}
//
//+ (void)removeFavorite:(ZBPackage *)package {
//    NSMutableArray *favorites = [[ZBSettings favoritePackages] mutableCopy];
//    BOOL isFavorited = [favorites containsObject:package.identifier];
//    if (isFavorited) {
//        [favorites removeObject:package.identifier];
//    }
//    [ZBSettings setFavoritePackages:favorites];
//}
//
//+ (void)blockAuthorOf:(ZBPackage *)package {
//    NSMutableDictionary *blockedAuthors = [[ZBSettings blockedAuthors] mutableCopy];
//
//    [blockedAuthors setObject:[package authorName] forKey:[package authorEmail] ?: [package authorName]];
//
//    [ZBSettings setBlockedAuthors:blockedAuthors];
//}
//
//+ (void)unblockAuthorOf:(ZBPackage *)package {
//    NSMutableDictionary *blockedAuthors = [[ZBSettings blockedAuthors] mutableCopy];
//
//    [blockedAuthors removeObjectForKey:[package authorName]];
//    if ([package authorEmail]) [blockedAuthors removeObjectForKey:[package authorEmail]];
//
//    [ZBSettings setBlockedAuthors:blockedAuthors];
//}

+ (void)share:(ZBPackage *)package {
    // Likely implement later, gets a bit complicated due to presentation
}

#pragma mark - Display Actions

+ (void)buttonTitleForPackage:(PLPackage *)package completion:(void (^)(NSString * _Nullable title))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *title = [self buttonTitleForPackage:package];
        if ([package mightRequirePayment]) {
//            [package purchaseInfo:^(ZBPurchaseInfo * _Nonnull info) {
//                if (info) { // Package does have purchase info
//                    BOOL installed = package.isInstalled;
//                    if (!info.purchased && !installed) { // If the user has not purchased the package
//                        NSString *title = info.price;
//                        if ([title isKindOfClass:[NSNumber class]]) {
//                            // Free package even with purchase info
//                            dispatch_async(dispatch_get_main_queue(), ^{
//                                completion([(NSNumber *)title stringValue]);
//                            });
//                            return;
//                        }
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            completion(info.price);
//                        });
//                        return;
//                    }
//                    else if (info.purchased && !installed) {
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            completion(@"Install");
//                        });
//                        return;
//                    }
//                }
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    completion(title);
//                });
//                return;
//            }];
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(title);
        });
    });
}

+ (void (^)(void))buttonActionForPackage:(PLPackage *)package controller:(UIViewController *)controller sender:(UIView *)sender completion:(nullable void(^)(void))completion {
    ZBPackageActionType actions = package.possibleActions;
    if ((actions & (actions - 1)) != 0) {
        return ^{
            UIAlertController *selectAction = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@)", package.name, package.version] message:nil preferredStyle:UIAlertControllerStyleActionSheet];

            for (UIAlertAction *action in [ZBPackageActions alertActionsForPackage:package controller:controller sender:sender completion:completion]) {
                [selectAction addAction:action];
            }

            selectAction.popoverPresentationController.sourceView = sender;
            [controller presentViewController:selectAction animated:YES completion:nil];
        };
    }
    else {
        return ^{
            // If the user has pressed the bar button twice (i.e. the same package is already in the Queue, present it
//            if ([[ZBQueue sharedQueue] contains:package inQueue:[self actionToQueue:actions]]) {
//                [[ZBAppDelegate tabBarController] openQueue:YES];
//            }
//            else {
                [self performAction:actions forPackage:package controller:controller sender:sender completion:^{
                    if (completion) completion();
                }];
//            }
        };
    }
}

+ (UISwipeActionsConfiguration *)swipeActionsForPackage:(ZBPackage *)package inTableView:(UITableView *)tableView {
//    NSMutableArray *swipeActions = [NSMutableArray new];
//
//    NSArray *actions = [package possibleActions];
//    for (NSNumber *number in actions) {
//        ZBPackageActionType action = number.intValue;
//
//        NSString *title = [self titleForAction:action useIcon:YES];
//        UIContextualActionStyle style = action == ZBPackageActionRemove ? UIContextualActionStyleDestructive : UIContextualActionStyleNormal;
//        UIContextualAction *swipeAction = [UIContextualAction contextualActionWithStyle:style title:title handler:^(UIContextualAction * _Nonnull contextualAction, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
////            [self performAction:action forPackage:package completion:nil];
//            completionHandler(YES);
//        }];
//
//        swipeAction.backgroundColor = [self colorForAction:action];
//
//        if (@available(iOS 13.0, *)) {
//            if ([ZBSettings swipeActionStyle] == ZBSwipeActionStyleIcon) {
//                swipeAction.image = [self systemImageForAction:action];
//            }
//        }
//
//        [swipeActions addObject:swipeAction];
//    }

//    return [UISwipeActionsConfiguration configurationWithActions:swipeActions];
    return NULL;
}

+ (NSArray <UIAlertAction *> *)alertActionsForPackage:(PLPackage *)package controller:(UIViewController *)controller sender:(UIView *)sender completion:(nullable void(^)(void))completion {
    NSMutableArray <UIAlertAction *> *alertActions = [NSMutableArray new];
    
    ZBPackageActionType actions = package.possibleActions;
    for (ZBPackageActionType action = 1; action <= ZBPackageActionSelectVersion; action = action << 1) {
        if ((actions & action) == 0) continue;
        NSString *title = [self titleForAction:action useIcon:NO];
        UIAlertActionStyle style = action == ZBPackageActionRemove ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault;
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:title style:style handler:^(UIAlertAction *alertAction) {
            [self performAction:action forPackage:package controller:controller sender:sender completion:nil];
            if (completion) completion();
        }];
        [alertActions addObject:alertAction];
    }
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:NULL];
    [alertActions addObject:cancel];
    
    return alertActions;
}

+ (NSArray <UIAlertAction *> *)extraAlertActionsForPackage:(PLPackage *)package selectionCallback:(void (^)(ZBPackageExtraActionType action))callback {
    NSMutableArray <UIAlertAction *> *alertActions = [NSMutableArray new];
    
    ZBPackageActionType actions = package.possibleExtraActions;
    for (ZBPackageExtraActionType action = 1; action <= ZBPackageExtraActionShare; action = action << 1) {
        if ((actions & action) == 0) continue;
        NSString *title = [self titleForExtraAction:action];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *alertAction) {
            [self performExtraAction:action forPackage:package completion:callback];
            if (callback) callback(action);
        }];
        [alertActions addObject:alertAction];
    }
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:NULL];
    [alertActions addObject:cancel];
    
    return alertActions;
}

+ (NSArray <UIPreviewAction *> *)previewActionsForPackage:(ZBPackage *)package inTableView:(UITableView *_Nullable)tableView {
//    NSMutableArray <UIPreviewAction *> *previewActions = [NSMutableArray new];
//
//    NSArray *actions = [package possibleActions];
//    for (NSNumber *number in actions) {
//        ZBPackageActionType action = number.intValue;
//
//        NSString *title = [self titleForAction:action useIcon:NO];
//        UIPreviewActionStyle style = action == ZBPackageActionRemove ? UIPreviewActionStyleDestructive : UIPreviewActionStyleDefault;
//        UIPreviewAction *previewAction = [UIPreviewAction actionWithTitle:title style:style handler:^(UIPreviewAction *previewAction, UIViewController *previewViewController) {
////            [self performAction:action forPackage:package completion:^{
////                if (tableView) {
////                    dispatch_async(dispatch_get_main_queue(), ^{
////                        [tableView reloadRowsAtIndexPaths:[tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
////                    });
////                }
////            }];
//        }];
//
//        [previewActions addObject:previewAction];
//    }
//
//    return previewActions;
    return NULL;
}

+ (NSArray <UIAction *> *)menuElementsForPackage:(ZBPackage *)package inTableView:(UITableView *_Nullable)tableView API_AVAILABLE(ios(13.0)) {
//    NSMutableArray <UIAction *> *uiActions = [NSMutableArray new];
//
//    NSArray *actions = [package possibleActions];
//    for (NSNumber *number in actions) {
//        ZBPackageActionType action = number.intValue;
//
//        NSString *title = [self titleForAction:action useIcon:NO];
//        UIImage *image = NULL;
//        if (@available(iOS 13.0, *)) {
//            image = [self systemImageForAction:action];
//        }
//
//        UIAction *uiAction = [UIAction actionWithTitle:title image:image identifier:nil handler:^(__kindof UIAction *uiAction) {
////            [self performAction:action forPackage:package completion:^{
////                if (tableView) {
////                    dispatch_async(dispatch_get_main_queue(), ^{
////                        [tableView reloadRowsAtIndexPaths:[tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
////                    });
////                }
////            }];
//        }];
//        [uiActions addObject:uiAction];
//    }
//
//    return uiActions;
    return NULL;
}

#pragma mark - Displaying Actions to User

+ (UIColor *)colorForAction:(ZBPackageActionType)action {
    switch (action) {
        case ZBPackageActionInstall:
        case ZBPackageActionSelectVersion:
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
        case ZBPackageActionSelectVersion:
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
    }
    
    UIImageSymbolConfiguration *imgConfig = [UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightHeavy];
    return [UIImage systemImageNamed:imageName withConfiguration:imgConfig];
}

+ (NSString *)titleForAction:(ZBPackageActionType)action useIcon:(BOOL)icon {
    switch (action) {
        case ZBPackageActionInstall:
        case ZBPackageActionSelectVersion:
            return NSLocalizedString(@"Get", @""); // ⇩
        case ZBPackageActionRemove:
            return NSLocalizedString(@"Remove", @""); // ╳
        case ZBPackageActionReinstall:
            return NSLocalizedString(@"Reinstall", @""); // ↺
        case ZBPackageActionUpgrade:
            return NSLocalizedString(@"Upgrade", @""); // ↑
        case ZBPackageActionDowngrade:
            return NSLocalizedString(@"Downgrade", @""); // ↓
        default:
            break;
    }
    return @"Undefined";
}

+ (NSString *)titleForExtraAction:(ZBPackageExtraActionType)action {
    switch (action) {
        case ZBPackageExtraActionShowUpdates:
            return NSLocalizedString(@"Show Updates", @"");
        case ZBPackageExtraActionHideUpdates:
            return NSLocalizedString(@"Hide Updates", @"");
        case ZBPackageExtraActionAddFavorite:
            return NSLocalizedString(@"Add to Favorites", @"");
        case ZBPackageExtraActionRemoveFavorite:
            return NSLocalizedString(@"Remove from Favorites", @"");
        case ZBPackageExtraActionBlockAuthor:
            return NSLocalizedString(@"Block Author", @"");
        case ZBPackageExtraActionUnblockAuthor:
            return NSLocalizedString(@"Unblock Author", @"");
        case ZBPackageExtraActionShare:
            return NSLocalizedString(@"Share Package", @"");
        default:
            return @"Undefined";
    }
}

+ (NSString *)buttonTitleForPackage:(PLPackage *)package {
    ZBPackageActionType actions = [package possibleActions];
    if ((actions & (actions - 1)) != 0) {
        return NSLocalizedString(@"Modify", @"");
    }
    else {
        return [self titleForAction:actions useIcon:NO];
    }
}

@end
