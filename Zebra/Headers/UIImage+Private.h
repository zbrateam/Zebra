//
//  UIImage+Private.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 6/5/2563 BE.
//  Copyright © 2563 Wilson Styres. All rights reserved.
//

#ifndef UIImage_Private_h
#define UIImage_Private_h

#define MIIconVariant NSUInteger
#define MIIconVariantHomeScreen 8

@interface UIImage (Private)
- (instancetype)_flatImageWithColor:(UIColor *)color;
- (instancetype)_applicationIconImageForFormat:(MIIconVariant)variant precomposed:(BOOL)precomposed scale:(CGFloat)scale;
@end


#endif /* UIImage_Private_h */
