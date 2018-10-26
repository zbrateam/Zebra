//
//  AUPMAppDelegate.h
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

@class AUPMDatabaseManager;

@interface AUPMAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UITabBarController *tabBarController;
@property (nonatomic, retain) AUPMDatabaseManager *databaseManager;

@end

