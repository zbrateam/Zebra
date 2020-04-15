//
//  ZBSectionSelectorTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 3/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSectionSelectorTableViewController : UITableViewController
@property void (^sectionsSelected)(NSArray *selectedSections);
@end

NS_ASSUME_NONNULL_END
