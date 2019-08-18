//
//  ZBConsoleCommandDelegate.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 18/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#ifndef ZBConsoleCommandDelegate_h
#define ZBConsoleCommandDelegate_h

@protocol ZBConsoleCommandDelegate
@optional
- (void)receivedData:(NSNotification *_Nullable)notif;
- (void)receivedErrorData:(NSNotification *_Nullable)notif;
@end


#endif /* ZBConsoleCommandDelegate_h */
