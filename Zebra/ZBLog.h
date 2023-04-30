//
//  ZBLog.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 22/7/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#ifndef ZBLog_h
#define ZBLog_h

#if DEBUG
#define ZBLog(...) NSLog(__VA_ARGS__)
#else
#define ZBLog(...)
#endif

#endif /* ZBLog_h */
