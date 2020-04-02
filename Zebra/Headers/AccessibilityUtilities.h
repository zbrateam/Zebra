//
//  AccessibilityUtilities.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 1/4/2563 BE.
//  Copyright © 2563 Wilson Styres. All rights reserved.
//

#ifndef AccessibilityUtilities_h
#define AccessibilityUtilities_h

@interface AXServer : NSObject
@end

@interface AXSpringBoardServer : AXServer
+ (instancetype)server;
- (void)registerSpringBoardActionHandler:(void (^)(int))handler withIdentifierCallback:(void (^)(int))idCallback;
@end

#endif /* AccessibilityUtilities_h */
