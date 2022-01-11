//
//  UIView+Private.h
//  Zebra
//
//  Created by Adam Demasi on 12/1/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#ifndef UIView_Private_h
#define UIView_Private_h

@interface UIView (Private)

@property (nonatomic, assign, setter=_setContinuousCornerRadius:) CGFloat _continuousCornerRadius;

@end

#endif /* UIView_Private_h */
