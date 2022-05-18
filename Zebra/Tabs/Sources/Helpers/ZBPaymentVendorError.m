//
//  ZBPaymentVendorError.m
//  Zebra
//
//  Created by Adam Demasi on 3/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBPaymentVendorError.h"
#import "NSObject+Zebra.h"

// Shorthand for simple blocks
#define λ(decl, expr) (^(decl) { return (expr); })

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Private model interfaces

@interface ZBPaymentVendorError (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

#pragma mark - JSON serialization

ZBPaymentVendorError *_Nullable ZBPaymentVendorErrorFromData(NSData *data, NSError **error)
{
    @try {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
        return *error ? nil : [ZBPaymentVendorError fromJSONDictionary:json];
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:@"JSONSerialization" code:-1 userInfo:@{ @"exception": exception }];
        return nil;
    }
}

ZBPaymentVendorError *_Nullable ZBPaymentVendorErrorFromJSON(NSString *json, NSStringEncoding encoding, NSError **error)
{
    return ZBPaymentVendorErrorFromData([json dataUsingEncoding:encoding], error);
}

NSData *_Nullable ZBPaymentVendorErrorToData(ZBPaymentVendorError *paymentError, NSError **error)
{
    @try {
        id json = [paymentError JSONDictionary];
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:kNilOptions error:error];
        return *error ? nil : data;
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:@"JSONSerialization" code:-1 userInfo:@{ @"exception": exception }];
        return nil;
    }
}

NSString *_Nullable ZBPaymentVendorErrorToJSON(ZBPaymentVendorError *sourceInfo, NSStringEncoding encoding, NSError **error)
{
    NSData *data = ZBPaymentVendorErrorToData(sourceInfo, error);
    return data ? [[NSString alloc] initWithData:data encoding:encoding] : nil;
}

@implementation ZBPaymentVendorError
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"error": @"error",
        @"recoveryURL": @"recoveryURL",
        @"invalidate": @"invalidate"
    };
}

+ (_Nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error
{
    return ZBPaymentVendorErrorFromData(data, error);
}

+ (_Nullable instancetype)fromJSON:(NSString *)json encoding:(NSStringEncoding)encoding error:(NSError *_Nullable *)error
{
    return ZBPaymentVendorErrorFromJSON(json, encoding, error);
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[self alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self zbra_setValues:dict forProperties:self.class.properties];
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:self.class.properties.allValues] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in self.class.properties) {
        id propertyName = self.class.properties[jsonName];
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    return dict;
}

- (NSData *_Nullable)toData:(NSError *_Nullable *)error
{
    return ZBPaymentVendorErrorToData(self, error);
}

- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error
{
    return ZBPaymentVendorErrorToJSON(self, encoding, error);
}
@end

NS_ASSUME_NONNULL_END
