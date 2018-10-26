//
//  AUPMDatabaseManager.h
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

@interface AUPMDatabaseManager : NSObject {
    BOOL _hasPackagesThatNeedUpdates;
    int _numberOfPackagesThatNeedUpdates;
    NSArray *_updateObjects;
}
- (void)firstLoadPopulation:(void (^)(BOOL success))completion;
- (void)updatePopulation:(void (^)(BOOL success))completion;
- (void)updateEssentials:(void (^)(BOOL success))completion;
- (void)deleteRepo:(AUPMRepo *)repo;
- (BOOL)hasPackagesThatNeedUpdates;
- (int)numberOfPackagesThatNeedUpdates;
- (NSArray *)updateObjects;
@end


NS_ASSUME_NONNULL_END
