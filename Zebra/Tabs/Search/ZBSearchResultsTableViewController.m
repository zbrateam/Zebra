//
//  ZBSearchResultsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/23/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBSearchResultsTableViewController.h"
#import <Packages/Helpers/ZBProxyPackage.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>

#import <Extensions/UIImageView+Zebra.h>

@interface ZBSearchResultsTableViewController ()

@end

@implementation ZBSearchResultsTableViewController

@synthesize filteredResults;

- (id)initWithNavigationController:(UINavigationController *)controller {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"searchResultsController"];
    
    if (self) {
        self.navController = controller;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self tableView] setBackgroundColor:[UIColor groupedTableViewBackgroundColor]];
}

#pragma mark - Table view data source

- (void)refreshTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView transitionWithView:self.tableView
          duration:0.35f
          options:UIViewAnimationOptionTransitionCrossDissolve
          animations:^(void) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self setNeedsStatusBarAppearanceUpdate];
            });
          } completion:nil];
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return filteredResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_live) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"liveSearchResultCell" forIndexPath:indexPath];
        ZBProxyPackage *proxyPackage = filteredResults[indexPath.row];
        
        cell.textLabel.text = proxyPackage.name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        [[cell imageView] sd_setImageWithURL:[proxyPackage iconURL] placeholderImage:[UIImage imageNamed:[proxyPackage section]]];
        [[cell imageView] resize:CGSizeMake(30, 30) applyRadius:false];
        
        return cell;
    }
    else {
        ZBPackageTableViewCell *packageCell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
        
        [packageCell updateData:filteredResults[indexPath.row]];
        
        return packageCell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    if (_live) {
        ZBProxyPackage *proxyPackage = filteredResults[indexPath.row];
        ZBPackageDepictionViewController *depiction = [[ZBPackageDepictionViewController alloc] initWithPackage:[proxyPackage loadPackage]];
        
        [[self navController] pushViewController:depiction animated:true];
    }
    else {
        ZBPackage *package = filteredResults[indexPath.row];
         
        ZBPackageDepictionViewController *depiction = [[ZBPackageDepictionViewController alloc] initWithPackage:package];
        
        [[self navController] pushViewController:depiction animated:true];
    }
}

@end
