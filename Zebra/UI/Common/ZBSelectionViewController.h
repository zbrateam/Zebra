//
//  ZBSelectionViewController.h
//  Zebra
//
//  Created by Wilson Styres on 11/17/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBSelectionDelegate.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    ZBSelectionTypeNormal,
    ZBSelectionTypeInverse,
} ZBSelectionType;

@interface ZBSelectionViewController : UITableViewController
@property (nonatomic) BOOL allowsMultiSelection;
@property ZBSelectionType selectionType;
@property NSArray *choices;
@property NSMutableArray *selections;
@property NSString *footer;
- (instancetype)initWithDelegate:(id <ZBSelectionDelegate>)delegate indexPath:(NSIndexPath *_Nullable)indexPath;
@end

NS_ASSUME_NONNULL_END
