//
//  ZBPackageFilter.m
//  Zebra
//
//  Created by Wilson Styres on 11/15/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPackageFilter.h"

#import <Managers/ZBSourceManager.h>
#import <Model/ZBSource.h>
#import <ZBSettings.h>

@implementation ZBPackageFilter

- (instancetype)initWithSource:(ZBSource *)source section:(NSString *)section {
    ZBPackageFilter *filter = [ZBSettings filterForSource:source section:section];
    if (filter) {
        filter.source = source;
        return filter;
    }
    
    self = [super init];
    
    if (self) {
        _source = source;
        if (section) {
            _canSetSection = NO;
            _sections = @[section];
        } else {
            _canSetSection = YES;
        }
        _role = [ZBSettings role];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    
    if (self) {
        _sections = [decoder decodeObjectForKey:@"sections"];
        _canSetSection = [decoder decodeBoolForKey:@"canSetSection"];
        _userSetRole = [decoder decodeBoolForKey:@"userSetRole"];
        if (_userSetRole) {
            _role = [decoder decodeIntegerForKey:@"role"];
        } else {
            _role = [ZBSettings role];
        }
        _commercial = [decoder decodeBoolForKey:@"commercial"];
        _favorited = [decoder decodeBoolForKey:@"favorited"];
        _installed = [decoder decodeBoolForKey:@"installed"];
        _sortOrder = [decoder decodeIntegerForKey:@"sortOrder"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_sections forKey:@"sections"];
    [coder encodeBool:_canSetSection forKey:@"canSetSection"];
    [coder encodeBool:_userSetRole forKey:@"userSetRole"];
    if (_userSetRole) {
        [coder encodeInteger:_role forKey:@"role"];
    }
    [coder encodeBool:_commercial forKey:@"commercial"];
    [coder encodeBool:_favorited forKey:@"favorited"];
    [coder encodeBool:_installed forKey:@"installed"];
    [coder encodeInteger:_sortOrder forKey:@"sortOrder"];
}

- (NSCompoundPredicate *)compoundPredicate {
    NSMutableArray *predicates = [NSMutableArray new];
    
    if (_searchTerm && _searchTerm.length) {
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name contains[cd] %@", _searchTerm];
        [predicates addObject:searchPredicate];
    }

    if (_canSetSection && _sections.count) {
        NSPredicate *sectionPredicate = [NSPredicate predicateWithFormat:@"NOT (section IN %@)", _sections];
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
        if (self.source.remote) {
            [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"lastSeen" ascending:NO selector:@selector(compare:)]];
        } else {
            [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"installedDate" ascending:NO selector:@selector(compare:)]];
        }
    } else if (self.sortOrder == ZBPackageSortOrderSize) {
        if (self.source.remote) {
            [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"downloadSize" ascending:NO selector:@selector(compare:)]];
        } else {
            [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"installedSize" ascending:NO selector:@selector(compare:)]];
        }
    }

    [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
    return descriptors;
}

- (BOOL)isActive {
    return _searchTerm || (_canSetSection && _sections.count) || self.userSetRole;
}

@end
