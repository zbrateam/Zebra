#import "UIImage+ImageWithColor.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIImage(ImageWithColor)

- (UIImage *)initWithColor:(UIColor *)color {
	CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    self = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return self;
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    return [[UIImage alloc] initWithColor:color];
}

@end