//
//  ZBPackagesByAuthorTableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/20/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackage.h"
#import "ZBTableViewController.h"

@interface ZBPackagesByAuthorTableViewController : ZBTableViewController
@property (nonatomic, strong) ZBPackage *package;
@property (nonatomic, strong) NSString *developerName;
@end
