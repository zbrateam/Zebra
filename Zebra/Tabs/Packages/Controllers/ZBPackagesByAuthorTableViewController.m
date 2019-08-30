//
//  ZBPackagesByAuthorTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/20/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackagesByAuthorTableViewController.h"
#import <Packages/Helpers/ZBPackageActionsManager.h>

@interface ZBPackagesByAuthorTableViewController () {
    NSArray *moreByAuthor;
}
@end

@implementation ZBPackagesByAuthorTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    moreByAuthor = [[ZBDatabaseManager sharedInstance] packagesByAuthor:self.package.author];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    self.navigationItem.title = self.developerName;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return moreByAuthor.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
    [cell setColors];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = [[ZBDatabaseManager sharedInstance] topVersionForPackage:[moreByAuthor objectAtIndex:indexPath.row]];
    [(ZBPackageTableViewCell *)cell updateData:package];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"segueMorePackagesToPackageDepiction" sender:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"segueMorePackagesToPackageDepiction"]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = sender;
        destination.package = [[ZBDatabaseManager sharedInstance] topVersionForPackage:[moreByAuthor objectAtIndex:indexPath.row]];
        destination.view.backgroundColor = [UIColor tableViewBackgroundColor];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = [moreByAuthor objectAtIndex:indexPath.row];
    return [ZBPackageActionsManager rowActionsForPackage:package indexPath:indexPath viewController:self parent:nil completion:^(void) {
        [tableView reloadData];
    }];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView setEditing:NO animated:YES];
}

@end
