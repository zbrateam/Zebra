// ZBSourceInfo.m

#import "ZBSourceInfo.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Private model interfaces

@interface ZBSourceInfo (JSONConversion)
- (NSDictionary *)JSONDictionary;
@end

@interface ZBAuthenticationBanner (JSONConversion)
- (NSDictionary *)JSONDictionary;
@end

#pragma mark - JSON serialization

NSData *_Nullable ZBSourceInfoToData(ZBSourceInfo *sourceInfo, NSError **error)
{
    @try {
        id json = [sourceInfo JSONDictionary];
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:kNilOptions error:error];
        return *error ? nil : data;
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:@"JSONSerialization" code:-1 userInfo:@{ @"exception": exception }];
        return nil;
    }
}

NSString *_Nullable ZBSourceInfoToJSON(ZBSourceInfo *sourceInfo, NSStringEncoding encoding, NSError **error)
{
    NSData *data = ZBSourceInfoToData(sourceInfo, error);
    return data ? [[NSString alloc] initWithData:data encoding:encoding] : nil;
}

@implementation ZBSourceInfo
+ (NSDictionary<NSString *, ZBJSONProperty *> *)properties
{
    static NSDictionary<NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"name": ZBJSONString(@"name"),
            @"icon": ZBJSONString(@"icon"),
            @"description": ZBJSONString(@"theDescription"),
            @"authentication_banner": ZBJSONObject(@"authenticationBanner", [ZBAuthenticationBanner class]),
        };
    }
    return properties;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBJSONPropertyNames(ZBSourceInfo.properties)] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBSourceInfo.properties) {
        NSString *propertyName = ZBSourceInfo.properties[jsonName].propertyName;
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"authentication_banner": [_authenticationBanner JSONDictionary],
    }];

    return dict;
}

- (NSData *_Nullable)toData:(NSError *_Nullable *)error
{
    return ZBSourceInfoToData(self, error);
}

- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error
{
    return ZBSourceInfoToJSON(self, encoding, error);
}
@end

@implementation ZBAuthenticationBanner
+ (NSDictionary<NSString *, ZBJSONProperty *> *)properties
{
    static NSDictionary<NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"message": ZBJSONString(@"message"),
            @"button": ZBJSONString(@"button"),
        };
    }
    return properties;
}

- (NSDictionary *)JSONDictionary
{
    return [self dictionaryWithValuesForKeys:ZBJSONPropertyNames(ZBAuthenticationBanner.properties)];
}
@end

NS_ASSUME_NONNULL_END
