//
//  ZBSourceManager.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@class ZBSource;
@class ZBBaseSource;

#import "ZBSourceVerificationDelegate.h"

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceManager : NSObject
@property (readonly) NSArray <ZBSource *> *sources;
//@property NSMutableSet <ZBBaseSource *> *verifiedSources;
+ (id)sharedInstance;
- (ZBSource *)sourceMatchingSourceID:(int)sourceID;
- (void)addSources:(NSSet <ZBBaseSource *> *)sources error:(NSError **_Nullable)error;
- (void)removeSources:(NSSet <ZBBaseSource *> *)sources error:(NSError **_Nullable)error;
- (void)verifySources:(NSSet <ZBBaseSource *> *)sources delegate:(id <ZBSourceVerificationDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
