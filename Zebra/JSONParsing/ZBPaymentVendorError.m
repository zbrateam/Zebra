//
//  ZBPaymentVendorError.m
//  Zebra
//
//  Created by Adam Demasi on 3/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBPaymentVendorError.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Private model interfaces

@interface ZBPaymentVendorError (JSONConversion)
- (NSDictionary *)JSONDictionary;
@end

#pragma mark - JSON serialization

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
+ (NSDictionary<NSString *, ZBJSONProperty *> *)properties
{
    static NSDictionary<NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"error": ZBJSONString(@"error"),
            @"recoveryURL": ZBJSONString(@"recoveryURL"),
            @"invalidate": ZBJSONNumber(@"invalidate")
        };
    }
    return properties;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBJSONPropertyNames(self.class.properties)] mutableCopy];

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
