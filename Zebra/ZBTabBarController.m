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

@synthesize hasUpdates;
@synthesize updates;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 10.0, *)) {
        UITabBarItem.appearance.badgeColor = [UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0];
    }
    
//    [self performBackgroundRefresh:false completion:^(BOOL success) {
//        if (!success) {
//            NSLog(@"Error!");
//        }
//    }];
}

- (void)performBackgroundRefresh:(BOOL)requested completion:(void (^)(BOOL success))completion {
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
            dispatch_async(dispatch_get_main_queue(), ^{
                UITabBarItem *sourcesItem = [sourcesController tabBarItem];
                sourcesItem.badgeValue = @"";
                
                for (UIView *badge in self.tabBar.subviews[2].subviews) {
                    if ([NSStringFromClass([badge class]) isEqualToString:@"_UIBadgeView"]) {\
                        UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
                        [loadingView setColor:[UIColor whiteColor]];
                        
                        [loadingView setCenter:badge.center];
                        [loadingView startAnimating];
                        [badge addSubview:loadingView];
                    }
                }
            });
            ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
            [databaseManager updateDatabaseUsingCaching:true completion:^(BOOL success, NSError * _Nonnull error) {
//                [self setHasUpdates:has];
//                [self setUpdates:up];
//                [self updatePackageTableView];
                [sourcesController tabBarItem].badgeValue = nil;
                completion(true);
            }];
        });
    }
    else {
        ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
        [databaseManager updateEssentials:^(BOOL success, NSArray * _Nonnull up, BOOL has) {
            if (success) {
                [self setHasUpdates:has];
                [self setUpdates:up];
                [self updatePackageTableView];
            }
            completion(true);
        }];
    }
}

- (void)updatePackageTableView {
    UINavigationController *packageNavController = self.viewControllers[2];
    ZBPackageListTableViewController *packageVC = packageNavController.viewControllers[0];
    
    [packageVC refreshTable];
    if ([self hasUpdates]) {
        NSLog(@"[Zebra] Has Updates!");
        [packageNavController tabBarItem].badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)[[self updates] count]];
        for (UIView *badge in self.tabBar.subviews[3].subviews) {
            if ([NSStringFromClass([badge class]) isEqualToString:@"_UIBadgeView"]) {\
                [badge setBackgroundColor:[UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0]];
            }
        }
        
        [packageVC refreshTable];
    }
    else {
        NSLog(@"[Zebra] No Updates :(");
        [packageNavController tabBarItem].badgeValue = nil;
        [packageVC refreshTable];
    }
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
