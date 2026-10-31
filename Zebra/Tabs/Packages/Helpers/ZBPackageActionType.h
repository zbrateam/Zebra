//
//  ZBPackageActionType.h
//  Zebra
//
//  Created by Wilson Styres on 4/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#ifndef ZBPackageActionType_h
#define ZBPackageActionType_h

typedef NS_ENUM(NSUInteger, ZBPackageActionType) {
    ZBPackageActionInstall,
    ZBPackageActionRemove,
    ZBPackageActionReinstall,
    ZBPackageActionDowngrade,
    ZBPackageActionUpgrade,
    ZBPackageActionSelectVersion,
    ZBPackageActionShowUpdates,
    ZBPackageActionHideUpdates,
};

#endif /* ZBPackageActionType_h */
