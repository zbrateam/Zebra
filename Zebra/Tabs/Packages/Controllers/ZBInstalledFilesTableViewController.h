//
//  ZBInstalledFilesTableViewController.h
//  Zebra
//
//  Created by midnightchips on 7/13/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBTableViewController.h"
#import "ZBPackage.h"

@interface ZBInstalledFilesTableViewController : ZBTableViewController
@property (nonatomic, strong) ZBPackage *package;
@end
