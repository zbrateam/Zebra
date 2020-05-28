//
//  ZBLegacyNotificationProvider.m
//  Zebra
//
//  Created by Arthur Chaloin on 28/05/2020.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBLegacyNotificationProvider.h"
#import <UIKit/UIKit.h>

@implementation ZBLegacyNotificationProvider

- (void)notify:(nonnull ZBNotification *)note {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    notification.alertAction = note.title;
    notification.alertBody = note.body;
    notification.fireDate = [NSDate date];
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.userInfo = note.userInfo;
    notification.category = @"INVITE_CATEGORY";

    [UIApplication.sharedApplication scheduleLocalNotification:notification];
}

- (void)requireNotificationsAccess {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge categories:nil]];
    }
}

@end
