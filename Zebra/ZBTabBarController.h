//
//  ZBTabBarController.h
//  Zebra
//
//  Created by Wilson Styres on 3/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Database/ZBDatabaseDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBTabBarController : UITabBarController <ZBDatabaseDelegate>
@property (nonatomic, strong) NSArray *updates;
@property (nonatomic, strong) NSMutableDictionary *repoBusyList;
@property (nonatomic) BOOL hasUpdates;
- (void)performBackgroundRefresh:(BOOL)requested;
- (void)checkForPackageUpdates;
- (BOOL)doesPackageIDHaveUpdate:(NSString *)packageID;
@end

NS_ASSUME_NONNULL_END
