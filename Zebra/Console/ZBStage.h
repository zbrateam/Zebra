//
//  ZBStage.h
//  Zebra
//
//  Created by Wilson Styres on 10/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#ifndef ZBStage_h
#define ZBStage_h

typedef NS_ENUM(NSUInteger, ZBStage) {
    ZBStageDownload = 0,
    ZBStageInstall,
    ZBStageReinstall,
    ZBStageRemove,
    ZBStageUpgrade,
    ZBStageDowngrade,
    ZBStageFinished
};

#endif /* ZBStage_h */
