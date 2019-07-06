//
//  ZBDevice.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Console/ZBConsoleCommandDelegate.h>

@interface ZBDevice : NSObject
//Device management
+ (BOOL)needsSimulation;
+ (NSString *_Nullable)UDID;
+ (NSString *_Nullable)deviceModelID;
+ (NSString *_Nullable)machineID;
+ (void)sbreload;
+ (void)uicache:(NSArray *_Nonnull)arguments observer:(NSObject <ZBConsoleCommandDelegate> * _Nullable)observer;
+ (BOOL)isChimera;
+ (BOOL)isElectra;
+ (BOOL)isUncover;
+ (NSString *_Nonnull)deviceType;

//Dark Mode
+ (BOOL)darkModeEnabled;
+ (BOOL)darkModeOledEnabled;
+ (void)setDarkModeEnabled:(BOOL)enabled;
+ (void)configureDarkMode;
+ (void)configureLightMode;
+ (void)applyThemeSettings;
+ (void)refreshViews;
+ (NSInteger)selectedColorTint;
@end
