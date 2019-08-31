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
+ (instancetype)sharedInstance;
+ (NSArray <NSString *> *)knownDistURLs;
- (NSMutableDictionary <NSNumber *, ZBRepo *> *)repos;
- (void)addSourceWithString:(NSString *)urlString response:(void (^)(BOOL success, NSString *error, NSURL *url))respond;
- (void)addSourcesFromString:(NSString *)sourcesString response:(void (^)(BOOL success, NSString *error, NSArray<NSURL *> *failedURLs))respond;
- (void)deleteSource:(ZBRepo *)delRepo;
- (NSString *)debLineFromRepo:(ZBRepo *)repo;
- (void)addDebLine:(NSString *)sourceLine;
- (void)transferFromCydia;
- (void)transferFromSileo;
- (void)needRecaching;
- (void)mergeSourcesFrom:(NSURL *)fromURL into:(NSURL *)destinationURL completion:(void (^)(NSError *error))completion;
- (NSString *)knownDebLineFromURLString:(NSString *)urlString;
- (NSArray <NSURL *> *)verifiedURLs;
@end

NS_ASSUME_NONNULL_END
