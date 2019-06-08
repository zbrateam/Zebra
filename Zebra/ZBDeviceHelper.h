//
//  ZBDeviceHelper.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBDeviceHelper : NSObject
+ (NSString *)UDID;
+ (NSString *)deviceModelID;
+ (NSString *)machineID;
@end

NS_ASSUME_NONNULL_END
