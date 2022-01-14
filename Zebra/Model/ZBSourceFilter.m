//
//  ZBSourceFilter.m
//  Zebra
//
//  Created by Wilson Styres on 1/1/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBSourceFilter.h"
#import "Zebra-Swift.h"

@implementation ZBSourceFilter

- (instancetype)init {
    ZBSourceFilter *filter = [ZBSettings sourceFilter];
    if (filter) return filter;
    
    self = [super init];
    
    if (self) {
        _stores = NO;
        _unusedSources = NO;
        _sortOrder = ZBSourceSortOrderName;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    
    if (self) {
        _stores = [decoder decodeBoolForKey:@"stores"];
        _unusedSources = [decoder decodeBoolForKey:@"unusedSources"];
        _sortOrder = [decoder decodeIntegerForKey:@"sortOrder"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeBool:_stores forKey:@"stores"];
    [coder encodeBool:_unusedSources forKey:@"unusedSources"];
    [coder encodeInteger:_sortOrder forKey:@"sortOrder"];
}

- (NSCompoundPredicate *)compoundPredicate {
    NSMutableArray *predicates = [NSMutableArray new];
    
    if (_searchTerm && _searchTerm.length) {
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"label contains[cd] %@ OR repositoryURI contains[cd] %@", _searchTerm, _searchTerm];
        [predicates addObject:searchPredicate];
    }
    
    if (_stores) {
        NSPredicate *storePredicate = [NSPredicate predicateWithFormat:@"paymentEndpointURL != NULL"];
        [predicates addObject:storePredicate];
    }
    
    if (_unusedSources) {
        NSPredicate *unusedSourcesPredicate = [NSPredicate predicateWithFormat:@"numberOfInstalledPackages == 0"];
        [predicates addObject:unusedSourcesPredicate];
    }

    return [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
}

- (NSArray <NSSortDescriptor *> *)sortDescriptors {
    NSMutableArray *descriptors = [NSMutableArray new];
    
    if (_sortOrder == ZBSourceSortOrderInstalledPackages) {
        [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"numberOfInstalledPackages" ascending:NO selector:@selector(compare:)]];
    }
    
    [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"label" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
    return descriptors;
}

- (BOOL)isActive {
    return (_searchTerm && _searchTerm.length) || _stores || _unusedSources;
}
@end
