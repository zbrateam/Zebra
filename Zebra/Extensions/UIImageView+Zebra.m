//
//  UIImageView+Zebra.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "UIColor+GlobalColors.h"
#import "UIImageView+Zebra.h"
#import "UIView+Private.h"
#import "UIImage+Private.h"
#import <SDWebImage/SDWebImage.h>
#import <objc/runtime.h>

static const void *ZBImageURLKey = &ZBImageURLKey;

@implementation UIImageView (Zebra)

- (NSURL *)zb_imageURL {
    return objc_getAssociatedObject(self, ZBImageURLKey);
}

- (void)zb_setImageURL:(NSURL *)url {
    objc_setAssociatedObject(self, ZBImageURLKey, url, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)applyBorder {
    self.layer.borderColor = [UIColor imageBorderColor].CGColor;
    self.layer.borderWidth = 0.5;
    self.clipsToBounds = YES;
}

- (void)removeBorder {
    self.layer.borderColor = [UIColor clearColor].CGColor;
    self.layer.borderWidth = 0.0;
    self.clipsToBounds = YES;
}

- (void)setColor:(UIColor *)color {
    CGSize size = CGSizeMake(30, 30);

    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    [color setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *colorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.image = colorImage;
    [self resize:size applyRadius:NO];
    
    self.layer.cornerRadius = size.width / 2;
    self.clipsToBounds = YES;
}

- (void)setLeftColor:(UIColor *)leftColor rightColor:(UIColor *)rightColor {
    if ([leftColor isEqual:rightColor]) {
        [self setColor:leftColor];
        return;
    }
    
    CGSize size = CGSizeMake(30, 30);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size.width, size.height), NO, 0.0);
    
    UIBezierPath *leftTriangle = [[UIBezierPath alloc] init];
    [leftTriangle moveToPoint:CGPointMake(0, 0)];
    [leftTriangle addLineToPoint:CGPointMake(0, size.height)];
    [leftTriangle addLineToPoint:CGPointMake(size.width, 0)];
    [leftTriangle closePath];
    
    [leftColor setFill];
    [leftTriangle fill];
    
    UIBezierPath *rightTriangle = [[UIBezierPath alloc] init];
    [rightTriangle moveToPoint:CGPointMake(size.width, size.height)];
    [rightTriangle addLineToPoint:CGPointMake(0, size.height)];
    [rightTriangle addLineToPoint:CGPointMake(size.width, 0)];
    [rightTriangle closePath];
    
    [rightColor setFill];
    [rightTriangle fill];

    UIImage *colorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.image = colorImage;
    [self resize:size applyRadius:NO];
    
    self.layer.cornerRadius = size.width / 2;
    self.clipsToBounds = YES;
}

- (void)setIconImage:(UIImage *)image variant:(MIIconVariant)variant {
    CGFloat size = 0;
    switch (variant) {
    case MIIconVariantSpotlight:
        size = 40;
        break;
    case MIIconVariantDefault:
        size = 60;
        break;
    case MIIconVariantSettings:
        size = 29;
        break;
    }

    UIScreen *screen = self.window.screen ?: [UIScreen mainScreen];
    CGRect rect = CGRectMake(0, 0, size, size);

    UIGraphicsBeginImageContextWithOptions(rect.size, NO, screen.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    [[UIColor whiteColor] setFill];
    CGContextFillRect(context, rect);

    [image drawInRect:rect];

    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.image = [image _applicationIconImageForFormat:variant precomposed:YES scale:screen.scale];
}

- (void)resize:(CGSize)size applyRadius:(BOOL)radius {
    UIScreen *screen = self.window.screen ?: [UIScreen mainScreen];
    UIGraphicsBeginImageContextWithOptions(size, NO, screen.scale);

    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    [self.image drawInRect:rect];
    
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (radius) {
        self.layer.cornerRadius = 0.2237 * size.width;
        if (@available(iOS 13, *)) {
            self.layer.cornerCurve = kCACornerCurveContinuous;
        } else if (@available(iOS 11, *)) {
            self._continuousCornerRadius = self.layer.cornerRadius;
        }
        self.clipsToBounds = YES;
    }
}

- (void)setRetinaImageWithURL:(NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completion {
    self.zb_imageURL = url;

    NSString *urlString = url.absoluteString;
    if (!urlString) {
        [self sd_setImageWithURL:nil placeholderImage:placeholder completed:completion];
        return;
    }

    // If the URL already has a scaled suffix, use it as-is
    NSRegularExpression *scalePattern = [NSRegularExpression regularExpressionWithPattern:@"@[0-9]+x\\.[^.]+$" options:0 error:nil];
    if ([scalePattern firstMatchInString:urlString options:kNilOptions range:NSMakeRange(0, urlString.length)]) {
        __weak typeof(self) weakSelf = self;
        [self sd_setImageWithURL:url placeholderImage:placeholder completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (![weakSelf.zb_imageURL isEqual:url]) {
                return;
            }
            if (completion) {
                completion(image, error, cacheType, imageURL);
            }
        }];
        return;
    }

    UIScreen *screen = self.window.screen ?: [UIScreen mainScreen];
    NSInteger scale = (NSInteger)screen.scale;

    NSString *extension = url.pathExtension;
    NSString *base = [url.absoluteString stringByDeletingPathExtension];

    __weak typeof(self) weakSelf = self;
    __block __weak void (^weakTryScale)(NSInteger);
    void (^tryScale)(NSInteger) = ^(NSInteger currentScale) {
        void (^strongTryScale)(NSInteger) = weakTryScale;
        NSURL *candidate = url;
        if (currentScale > 1) {
            candidate = [NSURL URLWithString:[NSString stringWithFormat:@"%@@%ldx.%@", base, (long)currentScale, extension]];
        }

        [weakSelf sd_setImageWithURL:candidate placeholderImage:placeholder completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (![weakSelf.zb_imageURL isEqual:url]) {
                return;
            }

            if (error && currentScale > 1) {
                strongTryScale(currentScale - 1);
            } else if (completion) {
                completion(image, error, cacheType, imageURL);
            }
        }];
    };
    weakTryScale = tryScale;

    tryScale(scale);
}

- (void)setRetinaImageWithURL:(NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self setRetinaImageWithURL:url placeholderImage:placeholder completed:nil];
}

@end
