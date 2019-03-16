//
//  ZBRepo.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBRepo.h"

@implementation ZBRepo

@synthesize origin;
@synthesize desc;
@synthesize baseFileName;
@synthesize baseURL;
@synthesize secure;
@synthesize repoID;
@synthesize iconURL;
@synthesize defaultRepo;
@synthesize suite;
@synthesize components;
@synthesize shortURL;

- (id)initWithOrigin:(NSString *)origin description:(NSString *)description baseFileName:(NSString *)bfn baseURL:(NSString *)baseURL secure:(BOOL)sec repoID:(int)repoIdentifier iconURL:(NSURL *)icoURL isDefault:(BOOL)isDefault suite:(NSString *)sweet components:(NSString *)comp shortURL:(NSString *)shortA {
    
    self = [super init];
    
    if (self) {
        [self setOrigin:origin];
        [self setDesc:description];
        [self setBaseFileName:bfn];
        [self setBaseURL:baseURL];
        [self setSecure:sec];
        [self setRepoID:repoIdentifier];
        [self setIconURL:icoURL];
        [self setDefaultRepo:isDefault];
        [self setSuite:sweet];
        [self setComponents:comp];
        [self setShortURL:shortA];
    }
    
    return self;
}

- (BOOL)isSecure {
    return secure;
}

@end
