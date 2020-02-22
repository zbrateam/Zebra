//
//  ZBSourceVerification.h
//  Zebra
//
//  Created by Wilson Styres on 1/6/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#ifndef ZBSourceVerification_h
#define ZBSourceVerification_h

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    ZBSourceVerifying,  //Currently verifying
    ZBSourceExists,     //Exists
    ZBSourceImaginary,  //Doesn't exist
    ZBSourceUnverified  //Not yet verified
} ZBSourceVerification;

#endif /* ZBSourceVerification_h */
