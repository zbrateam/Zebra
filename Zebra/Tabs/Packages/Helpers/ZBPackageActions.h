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

#import "ZBPackageActionType.h"

@interface ZBPackageActions : NSObject
+ (NSArray <UITableViewRowAction *> *)rowActionsForPackage:(ZBPackage *)package;
+ (NSArray <UIAlertAction *> *)alertActionsForPackage:(ZBPackage *)package;

// Might end up condensing these two
+ (NSArray <UIPreviewAction *> *)previewActionsForPackage:(ZBPackage *)package;
+ (NSArray <UIAction *> *)menuElementsForPackage:(ZBPackage *)package API_AVAILABLE(ios(13.0));

+ (UIColor *)colorForAction:(ZBPackageActionType)action;
+ (NSString *)titleForAction:(ZBPackageActionType)action useIcon:(BOOL)icon;
+ (NSString *)buttonTitleForPackage:(ZBPackage *)package;
@end
