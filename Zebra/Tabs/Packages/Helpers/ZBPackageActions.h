//
//  ZBPackageActions.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 13/5/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBPackage;
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Queue/ZBQueueType.h>
#import <Extensions/UIBarButtonItem+blocks.h>

#import "ZBPackageActionType.h"

@interface ZBPackageActions : NSObject

+ (void)install:(ZBPackage *)package;
+ (void)remove:(ZBPackage *)package;
+ (void)reinstall:(ZBPackage *)package;
+ (void)upgrade:(ZBPackage *)package;
+ (void)upgrade:(ZBPackage *)package toVersion:(NSString *)version;
+ (void)downgrade:(ZBPackage *)package;
+ (void)downgrade:(ZBPackage *)package toVersion:(NSString *)version;
+ (void)showUpdatesFor:(ZBPackage *)package;
+ (void)hideUpdatesFor:(ZBPackage *)package;

+ (UIBarButtonItem *)barButtonItemForPackage:(ZBPackage *)package;
+ (NSArray <UITableViewRowAction *> *)rowActionsForPackage:(ZBPackage *)package;
+ (NSArray <UIAlertAction *> *)alertActionsForPackage:(ZBPackage *)package;

// Might end up condensing these two
+ (NSArray <UIPreviewAction *> *)previewActionsForPackage:(ZBPackage *)package;
+ (NSArray <UIAction *> *)menuElementsForPackage:(ZBPackage *)package API_AVAILABLE(ios(13.0));

+ (UIColor *)colorForAction:(ZBPackageActionType)action;
+ (NSString *)titleForAction:(ZBPackageActionType)action useIcon:(BOOL)icon;
+ (NSString *)buttonTitleForPackage:(ZBPackage *)package;
@end
