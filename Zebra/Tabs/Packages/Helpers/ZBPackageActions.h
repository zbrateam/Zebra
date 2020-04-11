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
+ (void)barButtonItemForPackage:(ZBPackage *)package completion:(void (^)(UIBarButtonItem *barButton))completion;
+ (NSArray <UITableViewRowAction *> *)rowActionsForPackage:(ZBPackage *)package;
+ (NSArray <UIAlertAction *> *)alertActionsForPackage:(ZBPackage *)package;

// Might end up condensing these two
+ (NSArray <UIPreviewAction *> *)previewActionsForPackage:(ZBPackage *)package;
+ (NSArray <UIAction *> *)menuElementsForPackage:(ZBPackage *)package API_AVAILABLE(ios(13.0));
@end
