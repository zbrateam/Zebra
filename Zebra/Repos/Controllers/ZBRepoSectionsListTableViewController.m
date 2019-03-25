//
//  ZBRepoSectionsListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBRepoSectionsListTableViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Packages/Controllers/ZBPackageListTableViewController.h>

@interface ZBRepoSectionsListTableViewController ()

@end

@implementation ZBRepoSectionsListTableViewController

@synthesize repo;
@synthesize sectionReadout;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
    sectionReadout = [databaseManager sectionReadoutForRepo:repo];
    
    self.title = [repo origin];
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [sectionReadout[0] count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"repoSectionCell" forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
        cell.textLabel.text = @"All Packages";
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc]init];
        numberFormatter.locale = [NSLocale currentLocale];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        numberFormatter.usesGroupingSeparator = YES;
        
        cell.detailTextLabel.text = [numberFormatter stringFromNumber:[NSNumber numberWithInt:[databaseManager numberOfPackagesInRepo:repo]]];
    }
    else {
        NSString *section = [sectionReadout[0] objectAtIndex:indexPath.row - 1];
        cell.textLabel.text = section;
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc]init];
        numberFormatter.locale = [NSLocale currentLocale];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        numberFormatter.usesGroupingSeparator = YES;
        
        cell.detailTextLabel.text = [numberFormatter stringFromNumber:(NSNumber *)sectionReadout[1][indexPath.row - 1]];
    }
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ZBPackageListTableViewController *destination = [segue destinationViewController];
    destination.repo = repo;
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    if (indexPath.row != 0) {
        NSString *section = [sectionReadout[0] objectAtIndex:indexPath.row - 1];
        destination.section = section;
        destination.title = section;
    }
    else {
        destination.title = @"All Packages";
    }
}

@end
