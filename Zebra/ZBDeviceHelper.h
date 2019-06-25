//
//  ZBDeviceHelper.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Console/ZBConsoleCommandDelegate.h>

@interface ZBDeviceHelper : NSObject
+ (NSString *_Nullable)UDID;
+ (NSString *_Nullable)deviceModelID;
+ (NSString *_Nullable)machineID;
+ (void)sbreload;
+ (void)uicache:(NSArray *_Nonnull)arguments observer:(NSObject <ZBConsoleCommandDelegate> * _Nullable)observer;
+ (BOOL)isChimera;
+ (BOOL)isElectra;
+ (BOOL)isUncover;
@end
