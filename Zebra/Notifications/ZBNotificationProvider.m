//
//  ZBNotificationProvider.m
//  Zebra
//
//  Created by Arthur Chaloin on 28/05/2020.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBNotificationProvider.h"
#import <UserNotifications/UserNotifications.h>

@implementation ZBNotificationProvider

- (void)notify:(nonnull ZBNotification *)note {
    NSDate* now = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *date = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond|NSCalendarUnitTimeZone fromDate:[now dateByAddingTimeInterval:3]];

    UNCalendarNotificationTrigger* trigger = [UNCalendarNotificationTrigger
           triggerWithDateMatchingComponents:date repeats:NO];
    
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.title = note.title;
    content.body = note.body;
    content.userInfo = note.userInfo;

    UNNotificationRequest* request = [UNNotificationRequest
           requestWithIdentifier:@"MorningAlarm" content:content trigger:trigger];

    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
       if (error != nil) {
           NSLog(@"%@", error.localizedDescription);
       }
    }];
}

- (void)requireNotificationsAccess {
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[Zebra] Error: %@", error.localizedDescription);
        } else if (!granted) {
            NSLog(@"[Zebra] Authorization was not granted.");
        } else {
            NSLog(@"[Zebra] Notification access granted.");
        }
    }];
}

@end
