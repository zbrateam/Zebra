//
//  PLSource+Zebra.m
//  Zebra
//
//  Created by Wilson Styres on 5/5/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "PLSource+Zebra.h"

@implementation PLSource (Zebra)

+ (UIImage *)imageForSection:(NSString *)section {
    if (!section) return [UIImage imageNamed:@"Unknown"];
    
    NSString *imageName = [section stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    if ([imageName containsString:@"("]) {
        NSArray *components = [imageName componentsSeparatedByString:@"_("];
        if ([components count] < 2) {
            components = [imageName componentsSeparatedByString:@"("];
        }
        imageName = components[0];
    }
    
    UIImage *sectionImage = [UIImage imageNamed:imageName] ?: [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Applications/Zebra.app/Sections/%@.png", imageName]] ?: [UIImage imageNamed:@"Unknown"];
    return sectionImage;
}

@end
