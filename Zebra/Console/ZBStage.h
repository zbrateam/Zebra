//
//  ZBStage.h
//  Zebra
//
//  Created by Wilson Styres on 10/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#ifndef ZBStage_h
#define ZBStage_h

typedef enum {
    ZBStageDownload = 0,
    ZBStageInstall,
    ZBStageReinstall,
    ZBStageRemove,
    ZBStageUpgrade,
    ZBStageDowngrade,
    ZBStageFinished
} ZBStage;

#endif /* ZBStage_h */
