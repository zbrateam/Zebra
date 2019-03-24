//
//  ZBRepoSectionsListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZBRepo;

NS_ASSUME_NONNULL_BEGIN

@interface ZBRepoSectionsListTableViewController : UITableViewController
@property (nonatomic, strong) ZBRepo *repo;
@property (nonatomic, strong) NSArray *sections;
@end

NS_ASSUME_NONNULL_END
