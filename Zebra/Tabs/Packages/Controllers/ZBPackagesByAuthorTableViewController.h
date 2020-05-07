//
//  ZBPackagesByAuthorTableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/20/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Packages/Helpers/ZBPackage.h>
#import <Extensions/ZBTableViewController.h>

@interface ZBPackagesByAuthorTableViewController : ZBTableViewController
@property ZBPackage *package;
@property NSString *developerName;
@end
