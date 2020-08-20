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
- (void)verifySources:(NSSet <ZBBaseSource *> *)sources delegate:(id <ZBSourceVerificationDelegate>)delegate;
- (void)addBaseSources:(NSSet <ZBBaseSource *> *)baseSources;
- (void)deleteSource:(ZBSource *)source;
- (ZBSource *)sourceMatchingSourceID:(int)sourceID;
@end

NS_ASSUME_NONNULL_END
