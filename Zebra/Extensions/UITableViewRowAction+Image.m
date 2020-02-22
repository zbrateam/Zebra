//
//  UITableViewRowAction+Image.m
//  Zebra
//
//  Created by Wilson Styres on 11/4/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "UITableViewRowAction+Image.h"

@implementation UITableViewRowAction (Image)

- (void)setIcon:(UIImage *)image withText:(NSString *)text color:(UIColor *)color rowHeight:(CGFloat)height {
    UIImage *mask = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    CGSize stockSize = [[self title] sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18]}];
    CGFloat width = stockSize.width + 10;
    CGSize actionSize = CGSizeMake(width, height);
    
    UIGraphicsBeginImageContextWithOptions(actionSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    
    [color setFill];
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName: color, NSFontAttributeName: [UIFont systemFontOfSize:13.0]};
    CGSize textSize = [text sizeWithAttributes:attributes];
        
    CGPoint textPoint = CGPointMake((width - textSize.width) / 2, ((height - (textSize.height * 3)) / 2) + (textSize.height * 2));
    [text drawAtPoint:textPoint withAttributes:attributes];
    
    CGFloat maskHeight = textSize.height * 2;
    CGRect maskRect = CGRectMake((width - maskHeight) / 2, textPoint.y - maskHeight, maskHeight, maskHeight);
    [mask drawInRect:maskRect];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    [self setBackgroundColor:[UIColor colorWithPatternImage:result]];
    
    UIGraphicsEndImageContext();
    
//
//    CGFloat iconHeight = height * size;
//    CGFloat margin = (height - iconHeight) / 2;
//
//    UIGraphicsBeginImageContextWithOptions(CGSizeMake(height, height), NO, 0.0);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//
//    [color setFill];
//    CGContextFillRect(context, CGRectMake(0, 0, height, height));
//
//    [image drawInRect:CGRectMake(margin, margin, height, height)];
//
//    UIImage *actionImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    self.backgroundColor = [UIColor colorWithPatternImage:actionImage];
}

@end
