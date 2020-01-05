//
//  ZBCommunitySourcesTableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBDevice.h"
#import "UIColor+GlobalColors.h"
#import "ZBSourceManager.h"
#import "ZBAddRepoViewController.h"
@import SDWebImage;

@interface ZBCommunitySourcesTableViewController : UITableViewController <ZBAddRepoDelegate>
@property NSMutableArray <NSArray <NSDictionary *> *> *communitySources;
@property ZBSourceManager *repoManager;
@end
