//
//  ZBNotification.h
//  Zebra
//
//  Created by Arthur Chaloin on 28/05/2020.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#ifndef ZBNotification_h
#define ZBNotification_h

#import <Foundation/Foundation.h>

@interface ZBNotification : NSObject

@property () NSString *title;
@property () NSString *body;
@property () NSDictionary *userInfo;

@end

#endif /* ZBNotification_h */
