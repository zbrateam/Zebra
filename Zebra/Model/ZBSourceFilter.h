//
//  ZBSourceFilter.h
//  Zebra
//
//  Created by Wilson Styres on 1/1/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZBSourceSortOrder) {
    ZBSourceSortOrderName,
    ZBSourceSortOrderInstalledPackages,
};

@interface ZBSourceFilter : NSObject
@property (nonatomic, nullable) NSString *searchTerm;
@property (nonatomic) BOOL stores;
@property (nonatomic) BOOL unusedSources;
@property (nonatomic) ZBSourceSortOrder sortOrder;
- (NSCompoundPredicate *)compoundPredicate;
- (NSArray <NSSortDescriptor *> *)sortDescriptors;
- (BOOL)isActive;
@end

NS_ASSUME_NONNULL_END
