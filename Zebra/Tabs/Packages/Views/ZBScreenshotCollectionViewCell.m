//
//  ZBScreenshotCollectionViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-17.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBScreenshotCollectionViewCell.h"
#import "UIColor+GlobalColors.h"

@implementation ZBScreenshotCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self applyCustomizations];
}
     
- (void)applyCustomizations {
    self.screenshotImageView.layer.cornerRadius = 10;
    self.screenshotImageView.layer.masksToBounds = YES;
    self.screenshotImageView.layer.borderWidth = 1;
    self.screenshotImageView.layer.borderColor = [[UIColor imageBorderColor] CGColor];
}

@end
