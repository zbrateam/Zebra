//
//  ZBMigrationViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBMigrationViewController.h"

#import <Managers/ZBDatabaseManager.h>
#import <Tabs/ZBTabBarController.h>

@interface ZBMigrationViewController () {
    IBOutlet UIActivityIndicatorView *activityView;
    IBOutlet UILabel *migrationLabel;
}
@end

@implementation ZBMigrationViewController

#pragma mark - Initializers

- (id)init {
    self = [super init];
    
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:1.0 animations:^{
        self->activityView.alpha = 1.0;
        self->migrationLabel.alpha = 1.0;
    }];
    
    [[ZBDatabaseManager sharedInstance] migrateDatabase];
    UIApplication.sharedApplication.keyWindow.rootViewController = [[ZBTabBarController alloc] init];
}

@end
