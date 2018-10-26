//
//  AUPMTabBarController.m
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "AUPMTabBarController.h"
#import "AUPMDatabaseManager.h"
#import "AUPMAppDelegate.h"

@interface AUPMTabBarController ()

@end

@implementation AUPMTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self performBackgroundRefresh:false];
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
            [sourcesController tabBarItem].badgeValue = @"⏳";
            AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
            [databaseManager updatePopulation:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[self updatePackageTableView];
                    [sourcesController tabBarItem].badgeValue = nil;
                });
            }];
        });
    }
    else {
        AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
        [databaseManager updateEssentials:^(BOOL success) {
            if (success) {
                NSLog(@"Update package table view");
                //[self updatePackageTableView];
            }
        }];
    }
}

//- (void)updatePackageTableView {
//    UINavigationController *packageNavController = self.viewControllers[2];
//    AUPMPackageListViewController *packageVC = packageNavController.viewControllers[0];
//    AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
//    if ([databaseManager hasPackagesThatNeedUpdates]) {
//        [packageNavController tabBarItem].badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)[databaseManager numberOfPackagesThatNeedUpdates]];
//        [packageVC refreshTable];
//    }
//    else {
//        [packageNavController tabBarItem].badgeValue = nil;
//        [packageVC refreshTable];
//    }
//}

@end
