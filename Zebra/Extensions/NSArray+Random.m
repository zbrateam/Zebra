//
//  NSArray+Random.m
//  Zebra
//
//  Created by Wilson Styres on 1/8/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "NSArray+Random.h"

@implementation NSArray (Random)

- (NSArray *)shuffleWithCount:(NSUInteger)count {
    if (self.count < count) {
        return nil;
    } else if (self.count == count) {
        return self;
    }
    
    NSMutableSet *selection = [NSMutableSet new];
    while (selection.count < count) {
        id randomObject = [self objectAtIndex:arc4random() % self.count];
        [selection addObject:randomObject];
    }
    
    return selection.allObjects;
}

@end
