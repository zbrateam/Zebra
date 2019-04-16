//
//  Hyena.h
//  Zebra
//
//  Created by Wilson Styres on 3/20/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZBQueue;
@class ZBRepo;

NS_ASSUME_NONNULL_BEGIN

@interface Hyena : NSObject {
    NSArray *repos;
    ZBQueue *queue;
}
- (id)initWithSourceListPath:(NSString *)trail;
- (id)initWithSource:(ZBRepo *)repo;
- (void)downloadReposWithCompletion:(void (^)(NSDictionary *fileUpdates, BOOL success))completion ignoreCache:(BOOL)ignore;
- (void)downloadDebsFromQueueWithCompletion:(void (^)(NSArray *debs, BOOL success))completion;
@end

NS_ASSUME_NONNULL_END
