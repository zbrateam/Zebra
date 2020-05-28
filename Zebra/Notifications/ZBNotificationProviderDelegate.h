//
//  ZBNotificationProviderDelegate.h
//  Zebra
//
//  Created by Arthur Chaloin on 28/05/2020.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#ifndef ZBNotificationProviderDelegate_h
#define ZBNotificationProviderDelegate_h

#import <ZBNotification.h>

@protocol ZBNotificationProviderDelegate

- (void)requireNotificationsAccess;
- (void)notify:(nonnull ZBNotification *)note;

@end


#endif /* ZBNotificationProviderDelegate_h */
