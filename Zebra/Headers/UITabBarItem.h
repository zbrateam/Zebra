//
//  UITabBarItem.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 13/7/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#ifndef UITabBarItem_h
#define UITabBarItem_h

@import UIKit;

@interface UITabBarItem (Private)
- (void)setAnimatedBadge:(BOOL)animated;
- (UIView *)view;
@end

#endif /* UITabBarItem_h */
