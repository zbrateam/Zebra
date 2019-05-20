//
//  UIImage+Network.h
//  Fireside
//
//  Created by Soroush Khanlou on 8/25/12.
//
//

#import <UIKit/UIKit.h>

@interface UIImageView(Network)

@property (nonatomic, copy) NSURL *imageURL;

- (void) loadImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholder cachingKey:(NSString*)key;

@end
