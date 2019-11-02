//
//  _UITextLayoutView.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 2/11/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "_UITextLayoutView.h"

@implementation _UITextLayoutView

@synthesize delegate;

- (void)layoutSubviews {
    [delegate _layoutText];
}

@end
