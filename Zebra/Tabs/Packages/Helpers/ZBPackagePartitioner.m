//
//  ZBPackagePartitioner.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 2/11/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackagePartitioner.h"
#import "ZBPackage.h"

@implementation ZBPackagePartitioner

+ (NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector sectionIndexTitles:(NSMutableArray *)sectionIndexTitles packages:(NSArray <ZBPackage *> *)packages type:(ZBSortingType)type {
    switch (type) {
        case ZBSortingTypeABC: {
            UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
            [sectionIndexTitles addObjectsFromArray:[NSMutableArray arrayWithArray:[collation sectionIndexTitles]]];
            NSInteger sectionCount = [[collation sectionTitles] count];
            NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
            for (int i = 0; i < sectionCount; ++i) {
                [unsortedSections addObject:[NSMutableArray array]];
            }
            for (id object in array) {
                NSInteger index = [collation sectionForObject:object collationStringSelector:selector];
                [[unsortedSections objectAtIndex:index] addObject:object];
            }
            NSUInteger lastIndex = 0;
            NSMutableIndexSet *sectionsToRemove = [NSMutableIndexSet indexSet];
            NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
            for (NSMutableArray *section in unsortedSections) {
                if ([section count] == 0) {
                    NSRange range = NSMakeRange(lastIndex, [unsortedSections count] - lastIndex);
                    [sectionsToRemove addIndex:[unsortedSections indexOfObject:section inRange:range]];
                    lastIndex = [sectionsToRemove lastIndex] + 1;
                } else {
                    [sections addObject:[collation sortedArrayFromArray:section collationStringSelector:selector]];
                }
            }
            [sectionIndexTitles removeObjectsAtIndexes:sectionsToRemove];
            return sections;
        }
        case ZBSortingTypeDate: {
            NSMutableDictionary <NSDate *, NSMutableArray *> *partitions = [NSMutableDictionary new];
            for (ZBPackage *package in packages) {
                NSDate *groupedDate = nil;
                if (selector == @selector(lastSeenDate))
                    groupedDate = [package lastSeenDate];
                else if (selector == @selector(installedDate))
                    groupedDate = [package installedDate];
                if (groupedDate == nil)
                    continue;
                if (selector == @selector(installedDate)) {
                    NSTimeInterval time = floor([groupedDate timeIntervalSinceReferenceDate] / 60.0) * 60.0;
                    groupedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:time];
                }
                if (partitions[groupedDate] == nil) {
                    partitions[groupedDate] = [NSMutableArray array];
                }
                [partitions[groupedDate] addObject:package];
            }
            NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
            [sectionIndexTitles addObjectsFromArray:[[partitions allKeys] sortedArrayUsingDescriptors:@[dateDescriptor]]];
            NSMutableArray *sections = [NSMutableArray array];
            for (NSDate *date in sectionIndexTitles) {
                [sections addObject:partitions[date]];
            }
            return sections;
        }
        default:
            return nil;
    }
}

+ (NSString *)titleForHeaderInDateSection:(NSInteger)section sectionIndexTitles:(NSArray *)sectionIndexTitles dateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle {
    return [NSDateFormatter localizedStringFromDate:sectionIndexTitles[section] dateStyle:dateStyle timeStyle:timeStyle];
}

@end
