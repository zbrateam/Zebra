//
//  ZBDevice.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBCommandDelegate.h"

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
+ (NSString *_Nonnull)path;

+ (void)hapticButton;

+ (void)restartSpringBoard;
+ (void)restartDevice;
+ (void)uicache:(NSArray *_Nullable)arguments observer:(NSObject <ZBCommandDelegate> * _Nullable)observer;

+ (void)openURL:(NSURL *_Nonnull)url delegate:(UIViewController <SFSafariViewControllerDelegate> *_Nonnull)delegate;

+ (BOOL)isCheckrain;
+ (BOOL)isChimera;
+ (BOOL)isElectra;
+ (BOOL)isUncover;
+ (BOOL)isOdyssey;
+ (BOOL)isTaurine;
+ (BOOL)hasProcursus;

+ (BOOL)useIcon;

+ (void)exitZebra;
+ (void)exitZebraAfter:(int)seconds;

+ (BOOL)darkModeEnabled; //Only provided for legacy tweak support

+ (BOOL)buttonShapesEnabled;

@end
