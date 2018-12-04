//
//  ZBPackage.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBPackage.h"

@implementation ZBPackage

- (id)initWithPackageIdentifier:(NSString *)identifier name:(NSString *)name {
    self = [super init];
    if (self) {
        _packageID = identifier;
        _packageName = name;
    }
    return self;
}

- (NSString *)packageIdentifier {
    return _packageID;
}

- (NSString *)packageName {
    return _packageName;
}

@end
