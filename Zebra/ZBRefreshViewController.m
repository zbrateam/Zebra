//
//  ZBRefreshViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBRefreshViewController.h"
#import "ZBMainViewController.h"

#import <Database/ZBDatabaseManager.h>
#import <Parsel/Parsel.h>

@interface ZBRefreshViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation ZBRefreshViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
}

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
    
    ZBMainViewController *vc = [[ZBMainViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - UI

- (void)setupView {
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.hidesWhenStopped = YES;
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.spinner];
    [self.spinner startAnimating];
    
    [self configureLayout];
}

- (void)configureLayout {
    [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.spinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
}

@end
