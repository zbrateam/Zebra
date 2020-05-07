//
//  ZBTableViewController.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/5/2563 BE.
//  Copyright © 2563 Wilson Styres. All rights reserved.
//

#import "ZBTableViewController.h"

#import <UIColor+GlobalColors.h>

@interface ZBTableViewController ()

@end

@implementation ZBTableViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    self.navigationController.navigationBar.tintColor = [UIColor accentColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

@end
