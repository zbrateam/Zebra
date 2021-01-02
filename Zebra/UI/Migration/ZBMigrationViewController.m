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
#import <ZBLog.h>

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
        ZBLog(@"[Zebra] Initializing migration controller.");
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    ZBLog(@"[Zebra] Migration view did appear.");
    [UIView animateWithDuration:1.0 animations:^{
        self->activityView.alpha = 1.0;
        self->migrationLabel.alpha = 1.0;
    }];
    
    ZBLog(@"[Zebra] Beginning migration.");
    [[ZBDatabaseManager sharedInstance] migrateDatabase:YES];
    ZBLog(@"[Zebra] Migration finished. Loading tab controller.");
    UIApplication.sharedApplication.keyWindow.rootViewController = [[ZBTabBarController alloc] init];
}

@end
