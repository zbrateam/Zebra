//
//  ZBSourceFilter.m
//  Zebra
//
//  Created by Wilson Styres on 1/1/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBSourceFilter.h"

@implementation ZBSourceFilter

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
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
}

- (NSArray <NSSortDescriptor *> *)sortDescriptors {
    NSMutableArray *descriptors = [NSMutableArray new];
    
    [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"label" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
    return descriptors;
}

- (BOOL)isActive {
    return (_searchTerm && _searchTerm.length) || _stores;
}
@end
