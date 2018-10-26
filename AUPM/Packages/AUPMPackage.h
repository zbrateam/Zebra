//
//  AUPMPackage.h
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

@class AUPMRepo;
@protocol AUPMRepo;

@interface AUPMPackage : RLMObject
@property NSString *packageName;
@property NSString *packageIdentifier;
@property NSString *version;
@property NSString *section;
@property NSString *packageDescription;
@property NSString *depictionURL;
@property NSString *repoVersion;
@property NSString *tags;
@property BOOL installed;
@property AUPMRepo *repo;
- (BOOL)isInstalled;
- (BOOL)isFromRepo;
@end
RLM_ARRAY_TYPE(AUPMPackage)

NS_ASSUME_NONNULL_END
