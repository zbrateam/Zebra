//
//  ZBActionButton.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-11.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBActionButton.h"
#import "UIColor+GlobalColors.h"

@implementation ZBActionButton

- (void)awakeFromNib {
    [super awakeFromNib];
    [self applyCustomizations];
}

- (void)applyCustomizations {
    [self setBackgroundColor:[UIColor accentColor]];
    [self setContentEdgeInsets:UIEdgeInsetsMake(6, 20, 6, 20)];
    [self.layer setCornerRadius:self.frame.size.height / 2];
}

@end
