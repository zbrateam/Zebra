//
//  ZBSelectionViewController.h
//  Zebra
//
//  Created by Wilson Styres on 11/17/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UI/Common/Delegates/ZBSelectionDelegate.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    ZBSelectionTypeNormal,
    ZBSelectionTypeInverse,
} ZBSelectionType;

@interface ZBSelectionViewController : UITableViewController
@property (nonatomic) BOOL allowsMultiSelection;
- (instancetype)initWithChoices:(NSArray *)choices selections:(NSArray *_Nullable)selections selectionType:(ZBSelectionType)selectionType delegate:(id <ZBSelectionDelegate>)delegate indexPath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END
