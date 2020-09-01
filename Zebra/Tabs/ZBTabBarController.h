//
//  ZBTabBarController.h
//  Zebra
//
//  Created by Wilson Styres on 3/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@import UIKit;
#import "Sources/Helpers/ZBSourceDelegate.h"

#ifndef _TABBAR_H_
#define _TABBAR_H

NS_ASSUME_NONNULL_BEGIN

@interface ZBTabBarController : UITabBarController <ZBSourceDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSString * _Nullable forwardToPackageID;
@property (nonatomic, strong) NSString * _Nullable forwardedSourceBaseURL;
- (void)openQueue:(BOOL)openPopup;
- (void)updateQueueBar;
- (void)forwardToPackage;
- (void)updateQueueBarPackageCount:(int)count;
- (void)closeQueue;
- (BOOL)isQueueBarAnimating;
@end

NS_ASSUME_NONNULL_END

#endif
