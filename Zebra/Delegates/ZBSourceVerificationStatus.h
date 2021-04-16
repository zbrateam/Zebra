//
//  ZBSourceVerificationStatus.h
//  Zebra
//
//  Created by Wilson Styres on 4/15/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#ifndef ZBSourceVerificationStatus_h
#define ZBSourceVerificationStatus_h

typedef NS_ENUM(NSUInteger, ZBSourceVerificationStatus) {
    ZBSourceVerifying,  //Currently verifying
    ZBSourceExists,     //Exists
    ZBSourceImaginary,  //Doesn't exist
    ZBSourceUnverified  //Not yet verified
};

#endif /* ZBSourceVerificationStatus_h */
