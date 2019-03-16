//
//  ZBTabBarController.m
//  Zebra
//
//  Created by Wilson Styres on 3/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBTabBarController.h"
#import <Database/ZBDatabaseManager.h>
#import <Packages/Controllers/ZBPackageListTableViewController.h>
#import <ZBAppDelegate.h>

@interface ZBTabBarController ()

@end

@implementation ZBTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)performBackgroundRefresh:(BOOL)requested {
    BOOL timePassed = false;
    
    if (!requested) {
        NSDate *currentDate = [NSDate date];
        NSDate *lastUpdatedDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:@"lastUpdatedDate"];
        
        if (lastUpdatedDate != nil) {
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags fromDate:lastUpdatedDate toDate:currentDate options:0];
            
            timePassed = ([components minute] >= 30); //might need to be less
        }
        else {
            timePassed = true;
        }
    }
    
    if (requested || timePassed) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            UINavigationController *sourcesController = self.viewControllers[1];
            NSLog(@"Start!");
            dispatch_async(dispatch_get_main_queue(), ^{
                [sourcesController tabBarItem].badgeValue = @"Up!";
            });
            ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
            [databaseManager partialImport:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Finish!");
                    [self updatePackageTableView];
                    [sourcesController tabBarItem].badgeValue = nil;
                });
            }];
        });
    }
    else {
        ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
        [databaseManager updateEssentials:^(BOOL success) {
            if (success) {
                [self updatePackageTableView];
            }
        }];
    }
}

- (void)updatePackageTableView {
    UINavigationController *packageNavController = self.viewControllers[2];
    ZBPackageListTableViewController *packageVC = packageNavController.viewControllers[0];
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
    [packageVC refreshTable];
//    if ([databaseManager hasPackagesThatNeedUpdates]) {
//        [packageNavController tabBarItem].badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)[databaseManager numberOfPackagesThatNeedUpdates]];
//        [packageVC refreshTable];
//    }
//    else {
//        [packageNavController tabBarItem].badgeValue = nil;
//        [packageVC refreshTable];
//    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
