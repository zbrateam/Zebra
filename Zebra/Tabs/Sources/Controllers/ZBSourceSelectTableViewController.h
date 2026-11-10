//
//  ZBSourceSelectTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 3/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceListTableViewController.h"

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ZBSourceSelectionType) {
    ZBSourceSelectionTypeNormal,
    ZBSourceSelectionTypeInverse,
};

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceSelectTableViewController : ZBSourceListTableViewController
@property (nonatomic, copy) void (^sourcesSelected)(NSArray <ZBSource *> *selectedSources);
@property (nonatomic) ZBSourceSelectionType selectionType;
@property (nonatomic) NSUInteger limit;

- (id)initWithSelectionType:(ZBSourceSelectionType)type limit:(NSUInteger)limit;
- (id)initWithSelectionType:(ZBSourceSelectionType)type limit:(NSUInteger)sourceLimit selectedSources:(NSArray *)preSelectedSources;
@end

NS_ASSUME_NONNULL_END
