//
//  ZBDatabaseDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 4/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Console/ZBLogLevel.h>

@class ZBBaseSource;

#ifndef ZBDatabaseDelegate_h
#define ZBDatabaseDelegate_h

@protocol ZBDatabaseDelegate <NSObject>
- (void)databaseStartedUpdate;
- (void)databaseCompletedUpdate:(int)packageUpdates;
@optional
- (void)setSource:(ZBBaseSource *)source busy:(BOOL)busy;
- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level;
@end


#endif /* ZBDatabaseDelegate_h */
