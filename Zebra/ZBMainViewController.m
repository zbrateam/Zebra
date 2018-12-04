//
//  ZBMainViewController.m
//  Zebra
//
//  Created by Siddarth on 12/4/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBMainViewController.h"
#import "ZBPackageListTableViewController.h"
#import "ZBRepoListTableViewController.h"

@interface ZBMainViewController ()

@end

@implementation ZBMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViewControllers];
}

- (void)setupViewControllers {
    ZBRepoListTableViewController *repoListViewController = [[ZBRepoListTableViewController alloc] init];
    UINavigationController *repoListNavigationController = [[UINavigationController alloc] initWithRootViewController:repoListViewController];
    repoListNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Sources" image:nil tag:0];
    
    ZBPackageListTableViewController *packageListViewController = [[ZBPackageListTableViewController alloc] init];
    UINavigationController *packageListNavigationController = [[UINavigationController alloc] initWithRootViewController:packageListViewController];
    packageListNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Packages" image:nil tag:1];
    
    self.viewControllers = [[NSArray alloc] initWithObjects:repoListNavigationController, packageListNavigationController, nil];
}

@end
