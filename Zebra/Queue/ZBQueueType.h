//
//  ZBQueueType.h
//  Zebra
//
//  Created by Wilson Styres on 1/29/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#ifndef ZBQueueType_h
#define ZBQueueType_h

typedef enum {
    ZBQueueTypeInstall      = 1 << 0,
    ZBQueueTypeRemove       = 1 << 1,
    ZBQueueTypeReinstall    = 1 << 2,
    ZBQueueTypeUpgrade      = 1 << 3,
    ZBQueueTypeSelectable   = 1 << 4,
    ZBQueueTypeClear        = 1 << 5
} ZBQueueType;

#endif /* ZBQueueType_h */
