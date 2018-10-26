//
//  AUPMRepo.h
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

@class AUPMPackage;
@protocol AUPMPackage;

@interface AUPMRepo : RLMObject
@property NSString *repoName;
@property NSString *repoBaseFileName;
@property NSString *repoDescription;
@property NSString *repoURL;
@property int repoIdentifier;
@property BOOL defaultRepo;
@property NSString *suite;
@property NSString *components;
@property NSString *fullURL;
@property NSData *icon;
- (RLMResults<AUPMPackage *> *)packages;
@end
RLM_ARRAY_TYPE(AUPMRepo)
NS_ASSUME_NONNULL_END
