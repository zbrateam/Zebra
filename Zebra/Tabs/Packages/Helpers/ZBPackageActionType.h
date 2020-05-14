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
    ZBPackageActionSelectVersion,
} ZBPackageActionType;

typedef enum : NSUInteger {
    ZBPackageExtraActionShowUpdates,
    ZBPackageExtraActionHideUpdates,
    ZBPackageExtraActionAddWishlist,
    ZBPackageExtraActionRemoveWishlist,
    ZBPackageExtraActionBlockAuthor,
    ZBPackageExtraActionUnblockAuthor,
} ZBPackageExtraActionType;


#endif /* ZBPackageActionType_h */
