//
//  UITableViewRowAction+Image.h
//  Zebra
//
//  Created by Wilson Styres on 11/4/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableViewRowAction (Image)
- (void)setIcon:(UIImage *)image withText:(NSString *)text color:(UIColor *)color rowHeight:(CGFloat)height;
@end

NS_ASSUME_NONNULL_END
