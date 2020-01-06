//
//  ZBDevice.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NSTask.h>
#import <Console/ZBConsoleCommandDelegate.h>
@import SafariServices;

@interface ZBDevice : NSObject
// Device info
+ (BOOL)needsSimulation;
+ (BOOL)isSlingshotBrokenWithError:(NSError *_Nullable*_Nullable)error;
+ (NSString *_Nullable)UDID;
+ (NSString *_Nullable)deviceModelID;
+ (NSString *_Nullable)machineID;
+ (NSString *_Nonnull)deviceType;
+ (NSString *_Nonnull)debianArchitecture;


+ (void)hapticButton;

// Commands
+ (void)task:(NSTask *_Nullable)task withArguments:(NSArray *_Nullable)arguments;
+ (void)asRoot:(NSTask *_Nullable)task arguments:(NSArray *_Nullable)arguments;
+ (void)restartSpringBoard;
+ (void)uicache:(NSArray *_Nullable)arguments observer:(NSObject <ZBConsoleCommandDelegate> * _Nullable)observer;
+ (void)runCommandInPath:(NSString *_Nonnull)command asRoot:(BOOL)sling observer:(NSObject <ZBConsoleCommandDelegate> *_Nullable)observer;

// Utils
+ (void)openURL:(NSURL *_Nonnull)url delegate:(UIViewController <SFSafariViewControllerDelegate> *_Nonnull)delegate;

// Jailbreak tools
+ (BOOL)isCheckrain;
+ (BOOL)isChimera;
+ (BOOL)isElectra;
+ (BOOL)isUncover;
+ (NSString *_Nullable)packageManagementBinary;

// Dark Mode
+ (BOOL)darkModeEnabled;
+ (BOOL)darkModeOledEnabled;
+ (BOOL)darkModeThirteenEnabled;
+ (void)setDarkModeEnabled:(BOOL)enabled;
+ (void)configureDarkMode;
+ (void)configureLightMode;
+ (void)applyThemeSettings;
+ (void)refreshViews;
+ (NSInteger)selectedColorTint;

//Settings
+ (BOOL)useIcon;
@end
