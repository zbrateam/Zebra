//
//  ZBRepoManager.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@class ZBRepo;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBRepoManager : NSObject
- (void)addSourceWithString:(NSString *)urlString response:(void (^)(BOOL success, NSString *error, NSURL *url))respond;
-(void)addSourcesFromString:(NSString *)sourcesString response:(void (^)(BOOL success, NSString *error, NSArray<NSURL *> *failedURLs))respond;
- (void)deleteSource:(ZBRepo *)delRepo;
- (void)addDebLine:(NSString *)sourceLine;
- (void)transferFromCydia;
- (void)mergeSourcesFrom:(NSURL *)fromURL into:(NSURL *)destinationURL completion:(void (^)(NSError *error))completion;
@end

NS_ASSUME_NONNULL_END
