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
    ZBQueueTypeReinstall  = 1 << 1,
    ZBQueueTypeRemove     = 1 << 2,
    ZBQueueTypeUpgrade    = 1 << 3,
    ZBQueueTypeDowngrade  = 1 << 4,
    ZBQueueTypeDependency = 1 << 5,
    ZBQueueTypeClear      = 1 << 6
} ZBQueueType;

#endif /* ZBQueueType_h */
