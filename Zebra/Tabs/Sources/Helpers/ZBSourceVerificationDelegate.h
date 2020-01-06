//
//  ZBSourceVerificationDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 1/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@class ZBBaseSource;

#import "ZBSourceVerification.h"

#ifndef ZBSourceVerificationDelegate_h
#define ZBSourceVerificationDelegate_h

@protocol ZBSourceVerificationDelegate <NSObject>

- (void)source:(ZBBaseSource *)source status:(ZBSourceVerification)verified;

@end

#endif /* ZBSourceVerificationDelegate_h */
