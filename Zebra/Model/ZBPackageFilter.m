//
//  ZBPackageFilter.m
//  Zebra
//
//  Created by Wilson Styres on 11/15/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPackageFilter.h"

#import <Model/ZBSource.h>
#import <ZBSettings.h>

@interface ZBPackageFilter ()
@property (nonatomic) BOOL canSetSection;
@end

@implementation ZBPackageFilter

- (instancetype)initWithSource:(ZBSource *)source section:(NSString *)section {
    self = [super init];
    
    if (self) {
        _source = source;
        if (section) {
            _canSetSection = NO;
            _section = section;
        }
        _role = [ZBSettings role];
    }
    
    return self;
}

- (NSCompoundPredicate *)compoundPredicate {
    NSMutableArray *predicates = [NSMutableArray new];
    
    if (_searchTerm) {
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name contains[cd] %@", _searchTerm];
        [predicates addObject:searchPredicate];
    }
    
    if (_section) {
        NSPredicate *sectionPredicate = [NSPredicate predicateWithFormat:@"section == %@", _section];
        [predicates addObject:sectionPredicate];
    }
    
    NSPredicate *rolePredicate = [NSPredicate predicateWithFormat:@"role <= %d", _role];
    [predicates addObject:rolePredicate];
    
    if (_commercial) {
        NSPredicate *commercialPredicate = [NSPredicate predicateWithFormat:@"isPaid == YES"];
        [predicates addObject:commercialPredicate];
    }
    
    if (_favorited) {
        NSPredicate *favoritePredicate = [NSPredicate predicateWithFormat:@"isOnWishlist == YES"];
        [predicates addObject:favoritePredicate];
    }
    
    if (_installed) {
        NSPredicate *installedPredicate = [NSPredicate predicateWithFormat:@"isInstalled == YES"];
        [predicates addObject:installedPredicate];
    }
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
}

- (NSArray <NSSortDescriptor *> *)sortDescriptors {
    NSMutableArray *descriptors = [NSMutableArray new];
    
    if (self.sortOrder == ZBPackageSortOrderDate) {
        [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"lastSeen" ascending:NO selector:@selector(compare:)]];
    } else if (self.sortOrder == ZBPackageSortOrderSize) {
        [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"installedSize" ascending:YES selector:@selector(compare:)]];
    }

    [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
    return descriptors;
}

@end
