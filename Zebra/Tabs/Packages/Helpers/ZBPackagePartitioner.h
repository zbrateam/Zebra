//
//  ZBPackagePartitioner.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 2/11/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBPackage;

@import Foundation;
@import UIKit;
#import <ZBSettings.h>

@interface ZBPackagePartitioner : NSObject
+ (NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector sectionIndexTitles:(NSMutableArray *)sectionIndexTitles packages:(NSArray <ZBPackage *> *)packages type:(ZBSortingType)type;
+ (NSString *)titleForHeaderInDateSection:(NSInteger)section sectionIndexTitles:(NSArray *)sectionIndexTitles dateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle;
@end
