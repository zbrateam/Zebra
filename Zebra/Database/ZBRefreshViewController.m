//
//  ZBRefreshViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBRefreshViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Parsel/Parsel.h>

@interface ZBRefreshViewController ()

@end

@implementation ZBRefreshViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
    [databaseManager fullImport];
    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"aupm.db"];
//    NSString *testFile = [[NSBundle mainBundle] pathForResource:@"BigBoss" ofType:@"pack"];
//
//    sqlite3 *database;
//    sqlite3_open([databasePath UTF8String], &database);
//    importPackagesToDatabase([testFile UTF8String], database, 0);
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"navController"];
    [self presentViewController:vc animated:YES completion:nil];
}


@end
