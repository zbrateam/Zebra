//
//  UIAlertController+Show.h
//  Zebra
//
//  Created by Wilson Styres on 4/10/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIAlertController (Show)

- (void)show;
- (void)show:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
