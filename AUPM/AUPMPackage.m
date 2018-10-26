//
//  AUPMPackage.m
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "AUPMPackage.h"

@implementation AUPMPackage
+ (NSString *)primaryKey {
    return @"repoVersion";
}

- (BOOL)isInstalled {
    if ([self installed])
        return true;
    
    return ([[AUPMPackage objectsWhere:@"packageIdentifier == %@ AND version == %@", [self packageIdentifier], [self version]] count] > 1);
}

- (BOOL)isFromRepo {
    if ([self repo] != NULL)
        return true;
    
    return ([[AUPMPackage objectsWhere:@"packageIdentifier == %@ AND version == %@", [self packageIdentifier], [self version]] count] > 1);
}

@end

