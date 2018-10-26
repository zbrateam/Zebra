//
//  AUPMRepoManager.h
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

@class AUPMRepo;
@class AUPMPackage;

@interface AUPMRepoManager : NSObject
//+ (id)sharedInstance;
- (id)init;
- (NSArray *)managedRepoList;
- (NSArray<AUPMPackage *> *)packageListForRepo:(AUPMRepo *)repo;
- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList;
- (void)addSource:(NSURL *)sourceURL completion:(void (^)(BOOL success))completion;
- (void)deleteSource:(AUPMRepo *)delRepo;
@end

NS_ASSUME_NONNULL_END
