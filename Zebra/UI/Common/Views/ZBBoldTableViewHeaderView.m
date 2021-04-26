//
//  ZBBoldTableViewHeaderView.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-12.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBBoldTableViewHeaderView.h"
#import <Extensions/ZBColor.h>

@implementation ZBBoldTableViewHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.contentView.backgroundColor = [ZBColor systemBackgroundColor];
    self.actionButton.tintColor = [ZBColor accentColor];
}

@end
