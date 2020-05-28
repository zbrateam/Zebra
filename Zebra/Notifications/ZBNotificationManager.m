//
//  ZBNotificationManager.m
//  Zebra
//
//  Created by Arthur Chaloin on 27/05/2020.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBNotificationManager.h"
#import <ZBDatabaseManager.h>
#import <ZBSource.h>
#import <ZBLog.h>
#import <ZBNotificationProvider.h>
#import <ZBLegacyNotificationProvider.h>

@interface ZBNotificationManager ()

@property () BackgroundCompletionHandler completionHandler;

- (void)fetchCompleted:(UIBackgroundFetchResult)result;

@end

@implementation ZBNotificationManager

- (void)performBackgroundFetch:(BackgroundCompletionHandler)completionHandler {
    NSLog(@"[Zebra] Background fetch started");
    self.completionHandler = completionHandler;
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    [databaseManager updateDatabaseUsingCaching:NO userRequested:YES];
}

- (UIBackgroundFetchResult)notifyUpdatesIfNeeded {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    NSMutableArray<ZBPackage *> *packages = [databaseManager packagesWithUpdates];
    
    UIBackgroundFetchResult result = UIBackgroundFetchResultNoData;
    for (ZBPackage *package in packages) {
        if ([package didNotifyUser]) {
            continue;
        }
        
        [self notifyUpdateForPackage:package];
        [package setDidNotifyUser:YES];
        result = UIBackgroundFetchResultNewData;
    }
    
    return result;
}

- (void)notifyUpdateForPackage:(ZBPackage *)package {
    ZBNotification *note = [[ZBNotification alloc] init];
    
    note.title = [NSString stringWithFormat:NSLocalizedString(@"Update available for %@", @""), package.name];
    note.body = [NSString stringWithFormat:NSLocalizedString(@"Version %@ is available on %@.", @""), package.version, [package.source label]];
    
    id userInfoData[] = { [NSString stringWithFormat:@"zbra://packages/%@", package.identifier ] };
    id userInfoIndex[] = { @"openURL" };
    note.userInfo = [NSDictionary dictionaryWithObjects:userInfoData forKeys:userInfoIndex count:1];
    
    [self.delegate notify:note];
}

- (void)fetchCompleted:(UIBackgroundFetchResult)result {
    if (self.completionHandler != nil) {
        BackgroundCompletionHandler completionHandler = self.completionHandler;
        self.completionHandler = nil;
        NSLog(@"[Zebra] Background fetch finished");
        completionHandler(result);
    }
}

- (void)databaseCompletedUpdate:(int)numberOfUpdates {
    if (numberOfUpdates <= 0) {
        [self fetchCompleted:UIBackgroundFetchResultNoData];
        return;
    }
    
    UIBackgroundFetchResult result = [self notifyUpdatesIfNeeded];
    [self fetchCompleted:result];
}

- (void)databaseStartedUpdate {}
                           
+ (id)sharedInstance {
   static ZBNotificationManager *instance = nil;
   if (instance == nil) {
       instance = [ZBNotificationManager new];
       ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
       [databaseManager addDatabaseDelegate:instance];
       
       if (@available(iOS 10.0, *)) {
           instance.delegate = [[ZBNotificationProvider alloc] init];
       }
       else {
           instance.delegate = [[ZBLegacyNotificationProvider alloc] init];
       }
   }
   return instance;
}

@end
