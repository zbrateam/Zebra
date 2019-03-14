//
//  ZBRepo.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBRepo : NSObject
@property (nonatomic, strong) NSString *origin;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *baseFileName;
@property (nonatomic, strong) NSString *baseURL;
@property (nonatomic) BOOL secure;
@property (nonatomic) int repoID;
@property (nonatomic, strong) NSURL *iconURL;

- (id)initWithOrigin:(NSString *)origin description:(NSString *)description baseFileName:(NSString *)bfn baseURL:(NSString *)baseURL secure:(BOOL)sec repoID:(int)repoIdentifier iconURL:(NSURL *)icoURL;
- (BOOL)isSecure;
@end

NS_ASSUME_NONNULL_END
