//
//  ZBDependencyResolver.h
//  Zebra
//
//  Created by Wilson Styres on 3/26/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBDatabaseManager;
@class ZBPackage;
@class ZBQueue;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBDependencyResolver : NSObject {
    ZBDatabaseManager *databaseManager;
    ZBQueue *queue;
}
+ (id)sharedInstance;
- (BOOL)calculateDependenciesForPackage:(ZBPackage *)package;
@end

NS_ASSUME_NONNULL_END
