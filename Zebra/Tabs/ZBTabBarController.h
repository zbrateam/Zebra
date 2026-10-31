//
//  ZBTabBarController.h
//  Zebra
//
//  Created by Wilson Styres on 3/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBDatabaseDelegate.h"

#ifndef _TABBAR_H_
#define _TABBAR_H

NS_ASSUME_NONNULL_BEGIN

@interface ZBTabBarController : UITabBarController <ZBDatabaseDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSString *forwardToPackageID;
@property (nonatomic, strong) NSString *forwardedSourceBaseURL;
@property (nonatomic, strong) NSMutableDictionary *sourceBusyList;
- (void)setPackageUpdateBadgeValue:(NSInteger)updates;
- (void)setSourceRefreshIndicatorVisible:(BOOL)visible;
- (void)openQueue:(BOOL)openPopup;
- (void)clearSources;
- (void)updateQueueBar;
- (void)forwardToPackage;
- (void)updateQueueBarPackageCount:(NSUInteger)count;
- (void)dismissQueue;
- (void)closeQueue;
- (CGFloat)queueBarHeight;
@end

NS_ASSUME_NONNULL_END

#endif
