//
//  AUPMRefreshViewController.m
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "AUPMRefreshViewController.h"
#import "AUPMDatabaseManager.h"
#import "AUPMAppDelegate.h"
#import "AUPMTabBarController.h"

@interface AUPMRefreshViewController () {
    BOOL _action;
}
@end

@implementation AUPMRefreshViewController

- (id)init {
    self = [super init];
    if (self) {
        _action = 0;
    }
    return self;
}

- (id)initWithAction:(int)action {
    self = [super init];
    if (self) {
        _action = action;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
    if (_action == 0) {
        NSDate *methodStart = [NSDate date];
        [databaseManager firstLoadPopulation:^(BOOL success) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstSetupComplete"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
            NSLog(@"[AUPM] Completed in %f seconds", executionTime);
            
            [self goAway];
        }];
    }
    else if (_action == 1) {
        NSDate *methodStart = [NSDate date];
        [databaseManager updatePopulation:^(BOOL success) {
            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
            NSLog(@"[AUPM] Completed in %f seconds", executionTime);
            
            [self goAway];
        }];
    }
    else {
        NSLog(@"Invalid action...");
        [self goAway];
    }
}

- (void)goAway {
    if ([self presentingViewController]) {
        [self dismissViewControllerAnimated:true completion:nil];
    }
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        AUPMTabBarController *tabBarController = [storyboard instantiateViewControllerWithIdentifier:@"tabBarController"];
        
        [[UIApplication sharedApplication] keyWindow].rootViewController = tabBarController;
    }
}

@end
