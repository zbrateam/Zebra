//
//  ZBPackageActionType.h
//  Zebra
//
//  Created by Wilson Styres on 4/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#ifndef ZBPackageActionType_h
#define ZBPackageActionType_h

typedef enum : NSUInteger {
    ZBPackageActionInstall,
    ZBPackageActionRemove,
    ZBPackageActionReinstall,
    ZBPackageActionDowngrade,
    ZBPackageActionUpgrade,
    ZBPackageActionIgnoreUpdates,
    ZBPackageActionShowUpdates,
} ZBPackageActionType;

typedef NS_OPTIONS(NSUInteger, ZBPackageActionType) {
    ZBPackageActionInstall =      1 << 0,
    ZBPackageActionRemove =       1 << 1,
    ZBPackageActionReinstall =    1 << 3,
    ZBPackageActionUpgrade =      1 << 4,
    ZBPackageActionDowngrade =    1 << 5,
    ZBPackageActionShowUpdates =  1 << 6,
    ZBPackageActionHideUpdates =  1 << 7,
};

#endif /* ZBPackageActionType_h */
