//
//  ZBNotificationProvider.h
//  Zebra
//
//  Created by Arthur Chaloin on 28/05/2020.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#ifndef ZBNotificationProvider_h
#define ZBNotificationProvider_h

#import <ZBNotificationProviderDelegate.h>

@interface ZBNotificationProvider : NSObject <ZBNotificationProviderDelegate>

- (void)notify:(nonnull ZBNotification *)note API_AVAILABLE(ios(10));
- (void)requireNotificationsAccess API_AVAILABLE(ios(10));

@end

#endif /* ZBNotificationProvider_h */
