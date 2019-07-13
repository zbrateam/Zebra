//
//  ZBDevice.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NSTask.h>
#import <Console/ZBConsoleCommandDelegate.h>

@interface ZBDevice : NSObject
//Device management
+ (BOOL)needsSimulation;
+ (NSString *_Nullable)UDID;
+ (NSString *_Nullable)deviceModelID;
+ (NSString *_Nullable)machineID;
+ (void)asRoot:(NSTask *_Nullable)task arguments:(NSArray *_Nullable)arguments;
+ (void)sbreload;
+ (void)uicache:(NSArray *_Nonnull)arguments observer:(NSObject <ZBConsoleCommandDelegate> * _Nullable)observer;
+ (BOOL)isChimera;
+ (BOOL)isElectra;
+ (BOOL)isUncover;
+ (NSString *_Nonnull)deviceType;

//Dark Mode
+ (BOOL)darkModeEnabled;
+ (BOOL)darkModeOledEnabled;
+ (BOOL)darkModeThirteenEnabled;
+ (void)setDarkModeEnabled:(BOOL)enabled;
+ (void)configureDarkMode;
+ (void)configureLightMode;
+ (void)applyThemeSettings;
+ (void)refreshViews;
+ (NSInteger)selectedColorTint;
@end
