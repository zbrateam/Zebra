//
//  UIImageView+Async.h
//  Zebra
//
//  Created by Wilson Styres on 5/18/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (Async)
- (void)setImageFromURL:(NSURL *)url placeHolderImage:(UIImage *)placeholder;
@end

NS_ASSUME_NONNULL_END
