//
//  ZBBoldHeaderView.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-12.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBBoldHeaderView.h"
#import <Extensions/UIColor+GlobalColors.h>

@implementation ZBBoldHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.contentView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.actionButton.tintColor = [UIColor accentColor];
}

@end
