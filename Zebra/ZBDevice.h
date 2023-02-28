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

typedef NS_ENUM(NSUInteger, ZBJailbreak) {
    ZBJailbreakUnknown,
    ZBJailbreakSimulated,
    ZBJailbreakLegacy,
    ZBJailbreakCheckra1n,
    ZBJailbreakUncover,
    ZBJailbreakElectra,
    ZBJailbreakChimera,
    ZBJailbreakOdyssey,
    ZBJailbreakTaurine,
    ZBJailbreakCheyote,
    ZBJailbreakXinaA15,
    ZBJailbreakPalera1n,
    ZBJailbreakSocket,
    ZBJailbreakH3lix,
    ZBJailbreakBlizzard9,
    ZBJailbreakOpenpwnage,
    ZBJailbreakHomeDepot,
    ZBJailbreakKok3shi,
    ZBJailbreakP0laris,
    ZBJailbreakDoubleH3lix,
    ZBJailbreakMeridian,
    ZBJailbreakYalu,
    ZBJailbreakSaigon,
    ZBJailbreakG0blin,
    ZBJailbreakKok3shiX,
    ZBJailbreakMineekJB32,
    ZBJailbreakMineekJB64,
    ZBJailbreakMineekJB
};

typedef NS_ENUM(NSUInteger, ZBBootstrap) {
    ZBBootstrapUnknown,
    ZBBootstrapSimulated,
    ZBBootstrapTelesphoreo,
    ZBBootstrapProcursus,
    ZBBootstrapElucubratus
};

@interface UIApplication ()
- (void)suspend;
@end

NS_ASSUME_NONNULL_BEGIN

@interface ZBDevice : NSObject

+ (NSString *)userAgent;
+ (NSString *)downloadUserAgent;
+ (NSString *)webUserAgent;
+ (NSString *)themeName;

+ (BOOL)needsSimulation;
+ (BOOL)isSlingshotBroken:(NSError * _Nullable *)error;
+ (nullable NSString *)UDID;
+ (nullable NSString *)deviceModelID;
+ (nullable NSString *)machineID;
+ (NSString *)deviceType;
+ (NSArray <NSString *> *)allDebianArchitectures;
+ (NSString *)debianArchitecture;
+ (nullable NSString *)packageManagementBinary;
+ (NSString *)path;

+ (void)hapticButton;

+ (void)restartSpringBoard;
+ (void)restartDevice;
+ (void)uicache:(nullable NSArray *)arguments observer:(nullable NSObject <ZBCommandDelegate> *)observer;

+ (void)openURL:(NSURL *)url delegate:(UIViewController <SFSafariViewControllerDelegate> *)delegate;

+ (BOOL)isStashed;
+ (BOOL)isPrefixed;
+ (ZBBootstrap)bootstrap;
+ (ZBJailbreak)jailbreak;
+ (NSString *)bootstrapName;
+ (NSString *)jailbreakName;

+ (BOOL)useIcon;

+ (void)exitZebra;
+ (void)exitZebraAfter:(int)seconds;

+ (BOOL)darkModeEnabled; //Only provided for legacy tweak support

+ (BOOL)buttonShapesEnabled;

@end

NS_ASSUME_NONNULL_END
