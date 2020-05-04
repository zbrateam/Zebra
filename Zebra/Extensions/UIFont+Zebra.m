//
//  UIFont+Zebra.m
//  Zebra
//
//  Created by Tanner on 4/16/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "UIFont+Zebra.h"

@implementation UIFont (Zebra)
static UIFont *monospace, *monospaceBold;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat size = 11.0;
        if (@available(iOS 13, *)) {
            monospace = [UIFont monospacedSystemFontOfSize:size weight:UIFontWeightRegular];
            monospaceBold = [UIFont monospacedSystemFontOfSize:size weight:UIFontWeightBold];
        } else {
            monospace = [UIFont fontWithName:@"Menlo-Regular" size:size];
            monospaceBold = [UIFont fontWithName:@"Menlo-Bold" size:size];
        }
    });
}

+ (UIFont *)monospaceFont {
    return monospace;
}

+ (UIFont *)boldMonospaceFont {
    return monospaceBold;
}

@end
