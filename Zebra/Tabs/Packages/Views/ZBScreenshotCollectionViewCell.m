//
//  ZBScreenshotCollectionViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-17.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBScreenshotCollectionViewCell.h"

@implementation ZBScreenshotCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self applyCustomizations];
}
     
- (void)applyCustomizations {
    self.screenshotImageView.layer.cornerRadius = 5;
    self.screenshotImageView.layer.masksToBounds = YES;
}

@end
