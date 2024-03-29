//
//  PLPackage+Zebra.h
//  Zebra
//
//  Created by Wilson Styres on 4/4/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Plains/Plains.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLPackage (Zebra)
- (void)setPackageIconForImageView:(UIImageView *)imageView;
- (NSArray *)information;
@end

NS_ASSUME_NONNULL_END
