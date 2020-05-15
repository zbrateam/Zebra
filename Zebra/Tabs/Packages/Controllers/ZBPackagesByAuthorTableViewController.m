//
//  ZBPackagesByAuthorTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/20/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackagesByAuthorTableViewController.h"

#import <ZBAppDelegate.h>
#import <Extensions/UIColor+GlobalColors.h>
#import <Database/ZBDatabaseManager.h>
#import <Packages/Helpers/ZBPackageActions.h>
#import <Packages/Views/ZBPackageTableViewCell.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>

@interface ZBPackagesByAuthorTableViewController () {
    NSArray *moreByAuthor;
}
@property (nonatomic, strong) ZBPackage *package;
@end

@implementation ZBPackagesByAuthorTableViewController

- (id)initWithPackage:(ZBPackage *)package {
    self = [super init];
    
    if (self) {
        self.package = package;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    moreByAuthor = [[ZBDatabaseManager sharedInstance] packagesByAuthorName:self.package.authorName email:self.package.authorEmail fullSearch:YES];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    self.navigationItem.title = self.package.authorName;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    ZBPackage *package = [[ZBDatabaseManager sharedInstance] topVersionForPackage:moreByAuthor[indexPath.row]];
    [(ZBPackageTableViewCell *)cell updateData:package];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = [[ZBDatabaseManager sharedInstance] topVersionForPackage:[moreByAuthor objectAtIndex:indexPath.row]];
    if (package) {
        ZBPackageDepictionViewController *packageDepiction = [[ZBPackageDepictionViewController alloc] initWithPackage:package];
        
        [[self navigationController] pushViewController:packageDepiction animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ![[ZBAppDelegate tabBarController] isQueueBarAnimating];;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = moreByAuthor[indexPath.row];
    return [ZBPackageActions rowActionsForPackage:package inTableView:tableView];
    //reloadRow in completion
}
    
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView setEditing:NO animated:YES];
}

@end
