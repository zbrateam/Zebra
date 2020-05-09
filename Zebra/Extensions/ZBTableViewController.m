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

- (BOOL)hasSpinner {
    return NO;
}

- (BOOL)forceSetColors {
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setColors];
}

- (void)setColors {
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    self.navigationController.navigationBar.tintColor = [UIColor accentColor];
}

#pragma mark - Theming

- (void)asyncSetColors {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
        self.tableView.sectionIndexColor = [UIColor accentColor];
        self.navigationController.navigationBar.tintColor = [UIColor accentColor];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self hasSpinner]) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
           self.navigationItem.titleView = spinner;
           [spinner startAnimating];
           
           switch ([ZBSettings interfaceStyle]) {
               case ZBInterfaceStyleLight:
                   break;
               case ZBInterfaceStyleDark:
               case ZBInterfaceStylePureBlack:
                   spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
                   break;
           }
    }
    if ([self forceSetColors]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asyncSetColors) name:@"darkMode" object:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

@end
