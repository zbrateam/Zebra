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
    ZBQueueTypeInstall,
    ZBQueueTypeRemove,
    ZBQueueTypeReinstall,
    ZBQueueTypeUpgrade,
    ZBQueueTypeDowngrade // Note: Not really used directly, this is to make code less complicated - PoomSmart
} ZBQueueType;

#endif /* ZBQueueType_h */
