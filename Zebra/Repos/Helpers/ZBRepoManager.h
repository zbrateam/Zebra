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
- (void)addSourceWithURL:(NSString *)urlString response:(void (^)(BOOL success, NSString *error, NSURL *url))respond;
- (void)deleteSource:(ZBRepo *)delRepo;
- (void)addDebLine:(NSString *)sourceLine;
- (void)transferFromCydia;
@end

NS_ASSUME_NONNULL_END
