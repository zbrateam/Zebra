//
//  ZBLegacyNotificationProvider.h
//  Zebra
//
//  Created by Arthur Chaloin on 28/05/2020.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#ifndef ZBLegacyNotificationProvider_h
#define ZBLegacyNotificationProvider_h

#import <ZBNotificationProviderDelegate.h>

@interface ZBLegacyNotificationProvider : NSObject <ZBNotificationProviderDelegate>

- (void)notify:(nonnull ZBNotification *)note;
- (void)requireNotificationsAccess;

@end

#endif /* ZBLegacyNotificationProvider_h */
