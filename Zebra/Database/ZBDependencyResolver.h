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
    ZBPackage *package;
    ZBQueue *queue;
}
+ (NSArray *)separateVersionComparison:(NSString *)dependency;
- (id)initWithPackage:(ZBPackage *)package;
- (BOOL)immediateResolution;
@end

NS_ASSUME_NONNULL_END
