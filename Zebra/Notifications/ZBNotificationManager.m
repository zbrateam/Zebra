//
//  ZBNotificationManager.m
//  Zebra
//
//  Created by Arthur Chaloin on 06/06/2020.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBNotificationManager.h"
#import <ZBDatabaseManager.h>
#import <ZBSource.h>

@interface ZBNotificationManager ()

@property () BackgroundCompletionHandler completionHandler;
@property () ZBPackageList *oldUpdates;

- (void)fetchCompleted:(UIBackgroundFetchResult)result;

@end

@implementation ZBNotificationManager

- (void)ensureNotificationAccess {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[Zebra] Error: %@", error.localizedDescription);
        } else if (!granted) {
            NSLog(@"[Zebra] Authorization was not granted.");
        } else {
            NSLog(@"[Zebra] Notification access granted.");
        }
    }];
    
    center.delegate = self;
}

- (void)performBackgroundFetch:(BackgroundCompletionHandler)completionHandler {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    
    self.completionHandler = completionHandler;
    self.oldUpdates = [databaseManager packagesWithUpdates];

    [databaseManager updateDatabaseUsingCaching:NO userRequested:YES];
}

- (UIBackgroundFetchResult)notifyNewUpdatesBetween:(ZBPackageList *)oldUpdates
                                        newUpdates:(ZBPackageList *)newUpdates {
    UIBackgroundFetchResult result = UIBackgroundFetchResultNoData;
    
    for (ZBPackage *package in newUpdates) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", package.identifier];
        NSArray<ZBPackage *> *filteredPackages = [oldUpdates filteredArrayUsingPredicate:predicate];
        
        if (filteredPackages.count > 1) {
            NSLog(@"WARNING: Received multiple updates for the same package. This is most probably a developer error.");
            continue;
        }
        else if (filteredPackages.count <= 0) {
            [self notifyUpdateForPackage:package];
            result = UIBackgroundFetchResultNewData;
        }
        else {
            ZBPackage *oldPackage = filteredPackages[0];
            
            if (![package.version isEqualToString:oldPackage.version]) {
                [self notifyUpdateForPackage:package];
                result = UIBackgroundFetchResultNewData;
            }
        }
    }

    return result;
}

- (void)notifyUpdateForPackage:(ZBPackage *)package {
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Update available for %@", @""), package.name];
    NSString *text = [NSString stringWithFormat:NSLocalizedString(@"Version %@ is available on %@.", @""), package.version, [package.source label]];

    [self notify:text withTitle:title withUserInfo:@{
        @"openURL": [NSString stringWithFormat:@"zbra://packages/%@", package.identifier],
    }];
}

- (void)notify:(NSString *)body withTitle:(NSString *)title withUserInfo:(NSDictionary *)userInfo {
    NSDate* now = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *date = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond|NSCalendarUnitTimeZone fromDate:[now dateByAddingTimeInterval:3]];

    UNCalendarNotificationTrigger* trigger = [UNCalendarNotificationTrigger
           triggerWithDateMatchingComponents:date repeats:NO];

    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body = body;
    content.userInfo = userInfo;

    UNNotificationRequest* request = [UNNotificationRequest
           requestWithIdentifier:@"MorningAlarm" content:content trigger:trigger];

    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
       if (error != nil) {
           NSLog(@"%@", error.localizedDescription);
       }
    }];
}

- (void)fetchCompleted:(UIBackgroundFetchResult)result {
    self.oldUpdates = nil;

    if (self.completionHandler != nil) {
        BackgroundCompletionHandler completionHandler = self.completionHandler;
        self.completionHandler = nil;
        completionHandler(result);
    }
}

#pragma mark ZBDatabaseDelegate

- (void)databaseCompletedUpdate:(int)numberOfUpdates {
    if (numberOfUpdates <= 0) {
        [self fetchCompleted:UIBackgroundFetchResultNoData];
        return;
    }

    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    ZBPackageList *newUpdates = [databaseManager packagesWithUpdates];

    UIBackgroundFetchResult result = [self notifyNewUpdatesBetween:self.oldUpdates newUpdates:newUpdates];
    [self fetchCompleted:result];
}

- (void)databaseStartedUpdate {}

#pragma mark UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response withCompletionHandler:(nonnull void (^)(void))completionHandler {
    
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    NSURL *openURL = [NSURL URLWithString:[userInfo objectForKey:@"openURL"]];
    
    if (!openURL) {
        completionHandler();
        return;
    }

    [UIApplication.sharedApplication openURL:openURL
                                     options:[NSMutableDictionary dictionary]
                           completionHandler:^(BOOL _) {
        completionHandler();
    }];
}

#pragma mark Static methods

+ (id)sharedInstance {
   static ZBNotificationManager *instance = nil;
   if (instance == nil) {
       instance = [ZBNotificationManager new];
       ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
       [databaseManager addDatabaseDelegate:instance];
   }
   return instance;
}

@end
