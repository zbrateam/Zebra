//
//  ZBDevice.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@import Foundation;

#import <UIKit/UIApplication.h>

@interface UIApplication ()
- (void)suspend;
@end

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

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

+ (void)restartSpringBoard;
+ (void)uicache:(NSArray *_Nullable)bundleIdentifiers;

+ (void)openURL:(NSURL *_Nonnull)url sender:(UIViewController *_Nonnull)sender;

+ (BOOL)isCheckrain;
+ (BOOL)isChimera;
+ (BOOL)isElectra;
+ (BOOL)isUncover;
+ (BOOL)isOdyssey;

+ (BOOL)useIcon DEPRECATED_MSG_ATTRIBUTE("Use ZBSettings to determine the curent swipe action style. This method will be removed in the final version of Zebra 1.2.");;

+ (void)exitZebra;
+ (void)exitZebraAfter:(int)seconds;
+ (void)relaunchZebra;

+ (BOOL)darkModeEnabled DEPRECATED_MSG_ATTRIBUTE("Use ZBSettings to determine the curent interface style. This method will be removed in the final version of Zebra 1.2.");

+ (NSString *_Nonnull)downloadUserAgent;
+ (NSDictionary *_Nonnull)downloadHeaders;
+ (NSString *_Nonnull)depictionUserAgent;
+ (NSDictionary *_Nonnull)depictionHeaders;

+ (NSString *_Nonnull)jailbreakType;

@end
