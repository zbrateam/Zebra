//
//  ZBSourceVerificationDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 1/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@class ZBBaseSource;

#import <Foundation/Foundation.h>

#ifndef ZBSourceVerificationDelegate_h
#define ZBSourceVerificationDelegate_h

typedef enum : NSUInteger {
    ZBSourceVerifying,  //Currently verifying
    ZBSourceExists,     //Exists
    ZBSourceImaginary,  //Doesn't exist
    ZBSourceUnverified  //Not yet verified
} ZBSourceVerification;

@protocol ZBSourceVerificationDelegate <NSObject>

- (void)source:(ZBBaseSource *)source status:(ZBSourceVerification)verified;

@end

#endif /* ZBSourceVerificationDelegate_h */
