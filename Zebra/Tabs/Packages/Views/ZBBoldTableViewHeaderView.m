//
//  ZBBoldTableViewHeaderView.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-12.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBBoldTableViewHeaderView.h"
#import "UIColor+GlobalColors.h"

@implementation ZBBoldTableViewHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.contentView.backgroundColor = [UIColor tableViewBackgroundColor];
}

@end
