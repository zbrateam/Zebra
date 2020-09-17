//
//  ZBUtils.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 30/4/2563 BE.
//  Copyright © 2563 Wilson Styres. All rights reserved.
//

@import Foundation;

@interface ZBUtils : NSObject
+ (NSString * _Nonnull)decodeCString:(const char * _Nullable)cString fallback:(NSString * _Nullable)fallback;
+ (NSArray *_Nonnull)splitNameAndEmail:(NSString *_Nullable)string;
@end
