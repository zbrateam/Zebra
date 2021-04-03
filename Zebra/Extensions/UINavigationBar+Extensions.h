//
//  UINavigationBar+Extensions.h
//  Zebra
//
//  Created by Wilson Styres on 1/6/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UINavigationBar (Extensions)
@property (strong, nonatomic, readonly) UIProgressView *navProgressView;
@property (assign, setter=_setBackgroundOpacity:, nonatomic) double _backgroundOpacity;
@end

NS_ASSUME_NONNULL_END
