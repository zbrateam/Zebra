//
//  ZBSourceSelectTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 3/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceListViewController.h"

@import UIKit;

typedef enum : NSUInteger {
    ZBSourceSelectionTypeNormal,
    ZBSourceSelectionTypeInverse,
} ZBSourceSelectionType;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceSelectTableViewController : ZBSourceListViewController
@property void (^sourcesSelected)(NSArray <ZBSource *> *selectedSources);
@property ZBSourceSelectionType selectionType;
@property int limit;

- (id)initWithSelectionType:(ZBSourceSelectionType)type limit:(int)limit;
- (id)initWithSelectionType:(ZBSourceSelectionType)type limit:(int)sourceLimit selectedSources:(NSArray <ZBSource *> *)preSelectedSources;
@end

NS_ASSUME_NONNULL_END
