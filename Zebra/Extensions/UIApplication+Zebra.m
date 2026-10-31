//
//  UIApplication+Zebra.m
//  Zebra
//
//  Created by Adam Demasi on 1/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import "UIApplication+Zebra.h"

@implementation UIApplication (Zebra)

- (void)zb_openURL:(NSURL *)url options:(nullable NSDictionary <UIApplicationOpenExternalURLOptionsKey, id> *)options completionHandler:(void (^ _Nullable)(BOOL success))completion {
    if (@available(iOS 10, *)) {
        [self openURL:url options:options completionHandler:completion];
    } else {
        if (![self canOpenURL:url]) {
            if (completion) {
                completion(NO);
                return;
            }
        }

        [self openURL:url];

        if (completion) {
            completion(YES);
        }
    }
}

@end
