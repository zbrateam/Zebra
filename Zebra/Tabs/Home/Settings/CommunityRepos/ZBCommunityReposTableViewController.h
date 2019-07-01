//
//  ZBCommunityReposTableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBDevice.h"
#import "UIColor+GlobalColors.h"
#import "ZBDatabaseManager.h"
@import SDWebImage;

@interface ZBCommunityReposTableViewController : UITableViewController
@property NSString *jailbreakRepo;
@property NSArray *communityRepos;
@property NSMutableArray *availableManagers;
@end
