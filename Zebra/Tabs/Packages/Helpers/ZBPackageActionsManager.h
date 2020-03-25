//
//  ZBPackageActionsManager.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 13/5/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBPackage;
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Queue/ZBQueueType.h>

@interface ZBPackageActionsManager : NSObject
+ (void)installPackage:(ZBPackage *)package purchased:(BOOL)purchased;
+ (void)selectUpgradeableVersionForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent completion:(void (^)(void))completion;
+ (void)selectDowngradeableVersionForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent completion:(void (^)(void))completion;
+ (UIColor *)colorForAction:(ZBQueueType)queue;
+ (NSMutableArray <UIPreviewAction *> *)previewActionsForPackage:(ZBPackage *)package viewController:(UIViewController *)vc parent:(UIViewController *)parent;
+ (NSMutableArray <UIMenuElement *> *)contextMenuActionsForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent API_AVAILABLE(ios(13.0));
+ (NSMutableArray <UIAlertAction *> *)alertActionsForPackage:(ZBPackage *)package viewController:(UIViewController *)vc parent:(UIViewController *)parent;
+ (NSMutableArray <UITableViewRowAction *> *)rowActionsForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UITableViewController *)vc parent:(UIViewController *)parent completion:(void (^)(void))completion;
@end
