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

- (instancetype)init {
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
    NSArray *objects = [nib instantiateWithOwner:nil options:nil];
    for (NSObject *object in objects) {
        if ([object isKindOfClass:[self class]]) {
            ZBBoldHeaderView *view = (ZBBoldHeaderView *)object;
            view.backgroundColor = [UIColor tableViewBackgroundColor];
            view.actionButton.tintColor = [UIColor accentColor];
            return view;
        }
    }
    return nil;
}

@end
