//
//  ZBPackageFilter.h
//  Zebra
//
//  Created by Wilson Styres on 11/15/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZBSource;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZBPackageRole) {
    ZBPackageRoleUser,
    ZBPackageRoleHacker,
    ZBPackageRoleDeveloper,
    ZBPackageRoleDeity
};

typedef NS_ENUM(NSUInteger, ZBPackageSortOrder) {
    ZBPackageSortOrderName,
    ZBPackageSortOrderDate,
    ZBPackageSortOrderSize
};

@interface ZBPackageFilter : NSObject
@property (nonatomic) ZBSource *source;
@property (nonatomic, nullable) NSString *searchTerm;
@property (nonatomic, nullable) NSString *section;
@property (nonatomic) ZBPackageRole role;
@property (nonatomic) BOOL commercial;
@property (nonatomic) BOOL favorited;
@property (nonatomic) BOOL installed;
@property (nonatomic) ZBPackageSortOrder sortOrder;
- (instancetype)initWithSource:(ZBSource *)source section:(NSString *_Nullable)section;
- (NSCompoundPredicate *)compoundPredicate;
- (NSArray <NSSortDescriptor *> *)sortDescriptors;
@end

NS_ASSUME_NONNULL_END
