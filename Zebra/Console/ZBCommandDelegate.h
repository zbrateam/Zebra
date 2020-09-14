//
//  ZBCommandDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 9/9/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#ifndef ZBCommandDelegate_h
#define ZBCommandDelegate_h

@protocol ZBCommandDelegate

- (void)receivedData:(NSString *)data;
- (void)receivedErrorData:(NSString *)data;

@end

#endif /* ZBCommandDelegate_h */
