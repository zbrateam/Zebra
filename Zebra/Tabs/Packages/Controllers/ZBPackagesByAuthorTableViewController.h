//
//  ZBPackagesByAuthorTableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/20/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Database/ZBDatabaseManager.h>
#import <Packages/Views/ZBPackageTableViewCell.h>
#import <Extensions/UIColor+GlobalColors.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>

@interface ZBPackagesByAuthorTableViewController : UITableViewController
@property ZBPackage *package;
@property NSString *developerName;
@end
