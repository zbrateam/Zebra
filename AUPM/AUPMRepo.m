//
//  AUPMRepo.m
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "AUPMRepo.h"
#import "AUPMPackage.h"

@implementation AUPMRepo
+ (NSString *)primaryKey {
    return @"repoBaseFileName";
}
- (RLMResults<AUPMPackage *> *)packages {
    return [AUPMPackage objectsWhere:@"repo == %@", self];
}
@end
