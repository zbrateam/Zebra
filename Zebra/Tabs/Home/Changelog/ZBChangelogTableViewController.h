//
//  ZBChangelogTableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBTableViewController.h"

@class ZBGitHubRelease;

@interface ZBChangelogTableViewController : ZBTableViewController
@property NSMutableArray <ZBGitHubRelease *> *releases;
@end
