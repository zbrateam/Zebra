//
//  PLPackage+Zebra.m
//  Zebra
//
//  Created by Wilson Styres on 4/4/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "PLPackage+Zebra.h"

#import <Plains/PLSource.h>

#import <SDWebImage/SDWebImage.h>

@implementation PLPackage (Zebra)

- (void)setPackageIconForImageView:(UIImageView *)imageView {
    UIImage *sectionImage = [PLSource imageForSection:self.section];
    if (self.iconURL) {
        [imageView sd_setImageWithURL:self.iconURL placeholderImage:sectionImage];
    }
    else {
        [imageView setImage:sectionImage];
    }
}

@end
