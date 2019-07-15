//
//  UIImage+UIKitImage.m
//  Zebra
//
//  Created by midnightchips on 7/5/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//
#import <dlfcn.h>
#import "UIImage+UIKitImage.h"

__attribute__((unused)) static UIImage* UIKitImage(NSString* imgName) {
    NSString* artworkPath = @"/System/Library/PrivateFrameworks/UIKitCore.framework/Artwork.bundle";
    NSBundle* artworkBundle = [NSBundle bundleWithPath:artworkPath];
    BOOL loaded = [artworkBundle load];
    NSLog(@"LOADED %@", [NSNumber numberWithBool:loaded]);
    if (!artworkBundle) {
        artworkPath = @"/System/Library/Frameworks/UIKit.framework/Artwork.bundle";
        artworkBundle = [NSBundle bundleWithPath:artworkPath];
    }
    UIImage* img = [UIImage imageNamed:imgName inBundle:artworkBundle compatibleWithTraitCollection:nil];
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@implementation UIImage (UIKitImage)

+ (UIImage *)uikitImageWithString:(NSString *)name {
    return UIKitImage(name);
}

@end
