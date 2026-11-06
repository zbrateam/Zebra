//
//  ZBJSONObject.h
//  Zebra
//
//  Created by Adam Demasi on 6/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBJSONProperty.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBJSONObject : NSObject <ZBJSONDecodable>

@property (class, nonatomic, readonly) NSDictionary <NSString *, ZBJSONProperty *> *properties;

+ (nullable instancetype)fromData:(nullable NSData *)data error:(NSError *_Nullable *_Nullable)error;
+ (nullable NSArray *)arrayFromData:(nullable NSData *)data error:(NSError *_Nullable *_Nullable)error;
+ (nullable instancetype)fromJSONDictionary:(NSDictionary *)dict;

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict;

@property (nonatomic, readonly, getter=isValid) BOOL valid;

@end

NS_ASSUME_NONNULL_END
