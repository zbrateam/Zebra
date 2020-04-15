//
//  ZBSourceVerificationDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 1/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@class ZBBaseSource;

#import "ZBSourceVerificationStatus.h"

#ifndef ZBSourceVerificationDelegate_h
#define ZBSourceVerificationDelegate_h

@protocol ZBSourceVerificationDelegate <NSObject>
@optional

- (void)startedSourceVerification:(BOOL)multiple;
- (void)finishedSourceVerification:(NSArray *)existingSources imaginarySources:(NSArray *)imaginarySources;
- (void)source:(ZBBaseSource *)source status:(ZBSourceVerificationStatus)status;
- (void)verifyAndAdd:(NSSet *)baseSources;

@end

#endif /* ZBSourceVerificationDelegate_h */
