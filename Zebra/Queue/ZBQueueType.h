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
    ZBQueueTypeInstall    = 1 << 0,
    ZBQueueTypeRemove     = 1 << 1,
    ZBQueueTypeReinstall  = 1 << 2,
    ZBQueueTypeUpgrade    = 1 << 3,
    ZBQueueTypeDowngrade  = 1 << 4,
    ZBQueueTypeConflict   = 1 << 5,
    ZBQueueTypeDependency = 1 << 6,
    ZBQueueTypeClear      = 1 << 7
} ZBQueueType;

#endif /* ZBQueueType_h */
