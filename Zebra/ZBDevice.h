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

@interface UIApplication ()
- (void)suspend;
@end

@interface ZBDevice : NSObject
+ (BOOL)needsSimulation;
+ (BOOL)isSlingshotBroken:(NSError *_Nullable*_Nullable)error;
+ (NSString *_Nullable)UDID;
+ (NSString *_Nullable)deviceModelID;
+ (NSString *_Nullable)machineID;
+ (NSString *_Nonnull)deviceType;
+ (NSString *_Nonnull)debianArchitecture;
+ (NSString *_Nullable)packageManagementBinary;

+ (void)hapticButton;

+ (void)task:(NSTask *_Nullable)task withArguments:(NSArray *_Nullable)arguments;
+ (void)asRoot:(NSTask *_Nullable)task arguments:(NSArray *_Nullable)arguments;
+ (void)restartSpringBoard;
+ (void)uicache:(NSArray *_Nullable)arguments observer:(NSObject <ZBConsoleCommandDelegate> * _Nullable)observer;
+ (void)runCommandInPath:(NSString *_Nonnull)command asRoot:(BOOL)sling observer:(NSObject <ZBConsoleCommandDelegate> *_Nullable)observer;

+ (void)openURL:(NSURL *_Nonnull)url delegate:(UIViewController <SFSafariViewControllerDelegate> *_Nonnull)delegate;

+ (BOOL)isCheckrain;
+ (BOOL)isChimera;
+ (BOOL)isElectra;
+ (BOOL)isUncover;
+ (BOOL)isOdyssey;

+ (BOOL)useIcon;

+ (void)exitZebra;
+ (void)exitZebraAfter:(int)seconds;

+ (BOOL)darkModeEnabled; //Only provided for legacy tweak support

@end
