//
//  ZBCommunitySourcesTableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBSourceManager.h"

#import <Extensions/ZBTableViewController.h>

@interface ZBCommunitySourcesTableViewController : ZBTableViewController
@property NSMutableArray <NSArray <NSDictionary *> *> *communitySources;
@property ZBSourceManager *sourceManager;
@end
