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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceManager : NSObject
@property (nonatomic) NSMutableSet <ZBBaseSource *> *verifiedSources;
+ (id)sharedInstance;
+ (NSString *_Nullable)debLineForURL:(NSURL *)URL;
- (NSMutableDictionary <NSNumber *, ZBSource *> *)sources;
- (void)verifySources:(NSSet <ZBBaseSource *> *)sources delegate:(id <ZBSourceVerificationDelegate>)delegate;
- (void)addBaseSources:(NSSet <ZBBaseSource *> *)baseSources;
- (void)deleteSource:(ZBSource *)source;
- (void)needRecaching;
@end

NS_ASSUME_NONNULL_END
