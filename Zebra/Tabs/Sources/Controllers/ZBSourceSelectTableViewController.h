//
//  ZBSourceSelectTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 3/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceListTableViewController.h"

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    ZBSourceSelectionTypeNormal,
    ZBSourceSelectionTypeInverse,
} ZBSourceSelectionType;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceSelectTableViewController : ZBSourceListTableViewController
@property void (^sourcesSelected)(NSArray <ZBSource *> *selectedSources);
@property ZBSourceSelectionType selectionType;
@property int limit;

- (id)initWithSelectionType:(ZBSourceSelectionType)type limit:(int)limit;
@end

NS_ASSUME_NONNULL_END
