//
//  UIView+Zebra.h
//  Zebra
//
//  Created by Adam Demasi on 23/3/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Zebra)

@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic) CGFloat concentricCornerRadius;
@property (nonatomic, readonly, nullable) UIViewController *viewController;

@end

NS_ASSUME_NONNULL_END
