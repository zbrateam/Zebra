//
//  ZBQueuedPackage.m
//  Zebra
//
//  Created by Wilson Styres on 10/10/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueuedPackage.h"

@implementation ZBQueuedPackage

@synthesize dependencies;

- (id)initWithPackage:(ZBPackage *)package {
    self = [super init];
    
    if (self) {
        self.dependencies = [NSArray new];
        self.package = package;
    }
    
    return self;
}

- (NSString *)key {
    return [NSString stringWithFormat:@"%@-%@", [[self package] identifier], [[self package] version]];
}

- (void)addDependency:(id)package {
    NSMutableArray *deps = [dependencies mutableCopy];
    if ([package isKindOfClass:[ZBPackage class]]) {
        ZBQueuedPackage *queuedPackage = [[ZBQueuedPackage alloc] initWithPackage:package];
        [deps addObject:queuedPackage];
    }
    else if ([package isKindOfClass:[ZBQueuedPackage class]]) {
        [deps addObject:(ZBQueuedPackage *)package];
    }
    dependencies = deps;
}

@end
