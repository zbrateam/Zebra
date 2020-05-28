//
//  ZBNotificationManager.h
//  Zebra
//
//  Created by Arthur Chaloin on 27/05/2020.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#ifndef ZBNotificationManager_h
#define ZBNotificationManager_h

#import <UIKit/UIKit.h>
#import <ZBDatabaseDelegate.h>
#import <ZBPackage.h>
#import <ZBNotificationProviderDelegate.h>

typedef void (^BackgroundCompletionHandler)(UIBackgroundFetchResult);

@interface ZBNotificationManager : NSObject <ZBDatabaseDelegate>

@property (nonatomic, nullable) id <ZBNotificationProviderDelegate> delegate;

- (void)performBackgroundFetch:(nonnull BackgroundCompletionHandler)completionHandler;
- (void)notifyUpdateForPackage:(nonnull ZBPackage *)package;
- (UIBackgroundFetchResult)notifyUpdatesIfNeeded;

+ (nonnull instancetype)sharedInstance;

@end

#endif /* ZBNotificationManager_h */
