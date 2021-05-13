//
//  ZBSectionSelectorTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 3/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPreferencesViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBSectionSelectorTableViewController : ZBPreferencesViewController
@property void (^sectionsSelected)(NSArray *selectedSections);
@end

NS_ASSUME_NONNULL_END
