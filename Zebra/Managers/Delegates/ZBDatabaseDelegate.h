//
//  ZBDatabaseDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 4/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Console/ZBLogLevel.h>

@class ZBBaseSource;
@class ZBSource;

NS_ASSUME_NONNULL_BEGIN

#ifndef ZBDatabaseDelegate_h
#define ZBDatabaseDelegate_h

@protocol ZBDatabaseDelegate <NSObject>
- (void)databaseStartedUpdate;
- (void)databaseCompletedUpdate;
@optional
- (void)startedImportingSource:(ZBBaseSource *)source;
- (void)finishedImportingSource:(ZBSource *)source error:(NSError *_Nullable)error;
- (void)packageUpdatesAvailable:(int)numberOfUpdates;
- (void)setSource:(ZBBaseSource *)source busy:(BOOL)busy DEPRECATED_MSG_ATTRIBUTE("Please use startedImportingSource or finishedImportingSource instead");
- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level;
@end

#endif /* ZBDatabaseDelegate_h */

NS_ASSUME_NONNULL_END
