//
//  UIImageView+Async.m
//  Zebra
//
//  Created by Wilson Styres on 5/18/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "UIImageView+Async.h"

@implementation UIImageView (Async)

- (void)setImageFromURL:(NSURL *)url placeHolderImage:(UIImage *)placeholder {
    self.image = placeholder;
    [self resizeImage];
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data != NULL) {
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = image;
                [self resizeImage];
            });
        }
    }];
    
    [dataTask resume];
}

- (void)resizeImage {
    if (self.image != NULL) {
        CGSize itemSize = CGSizeMake(35, 35);
        UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
        [self.image drawInRect:imageRect];
        self.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
}

@end
