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
    return [sectionReadout[0] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"repoSectionCell" forIndexPath:indexPath];
    
    NSString *section = [sectionReadout[0] objectAtIndex:indexPath.row];
    cell.textLabel.text = section;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", (NSNumber *)sectionReadout[1][indexPath.row]];
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ZBPackageListTableViewController *destination = [segue destinationViewController];
    destination.repoID = [repo repoID];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSString *section = [sectionReadout[0] objectAtIndex:indexPath.row];
    destination.section = section;
}

@end
