//
//  ZBPackageFilter.m
//  Zebra
//
//  Created by Wilson Styres on 11/15/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPackageFilter.h"

@implementation ZBPackageFilter

- (instancetype)initWithSection:(NSString *)section role:(ZBPackageRole)role {
    self = [super init];
    
    if (self) {
        _section = section;
        _role = role;
    }
    
    return self;
}

@end
