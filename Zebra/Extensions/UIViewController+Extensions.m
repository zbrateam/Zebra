//
//  UIViewController+Extensions.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-06-14.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "UIViewController+Extensions.h"

@implementation UIViewController (Extensions)

- (BOOL)isModal {
    if([self presentingViewController])
        return YES;
    if([[[self navigationController] presentingViewController] presentedViewController] == [self navigationController])
        return YES;
    if([[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]])
        return YES;

   return NO;
}

@end
