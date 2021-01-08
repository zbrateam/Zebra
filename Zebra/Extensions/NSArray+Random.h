//
//  NSArray+Random.h
//  Zebra
//
//  Created by Wilson Styres on 1/8/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (Random)
- (NSArray *)shuffleWithCount:(NSUInteger)count;
@end

NS_ASSUME_NONNULL_END
