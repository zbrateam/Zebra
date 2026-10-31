//
//  UIApplication+Zebra.h
//  Zebra
//
//  Created by Adam Demasi on 1/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (Zebra)

- (void)zb_openURL:(NSURL *)url options:(nullable NSDictionary <UIApplicationOpenExternalURLOptionsKey, id> *)options completionHandler:(void (^ _Nullable)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
