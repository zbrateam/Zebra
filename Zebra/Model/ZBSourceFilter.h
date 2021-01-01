//
//  ZBSourceFilter.h
//  Zebra
//
//  Created by Wilson Styres on 1/1/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceFilter : NSObject
@property (nonatomic, nullable) NSString *searchTerm;
- (NSCompoundPredicate *)compoundPredicate;
- (NSArray <NSSortDescriptor *> *)sortDescriptors;
- (BOOL)isActive;
@end

NS_ASSUME_NONNULL_END
