//
//  ZBPackageActionsManager.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 13/5/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBPackage;
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface ZBPackageActionsManager : NSObject
+ (void)presentQueue:(UIViewController *)vc parent:(UIViewController *)parent;
+ (void)downgradePackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)vc parent:(UIViewController *)parent;
+ (NSArray *)actionsForPackage:(ZBPackage *)package indexPath:(NSIndexPath *)indexPath viewController:(UITableViewController *)vc parent:(UIViewController *)parent;
@end
