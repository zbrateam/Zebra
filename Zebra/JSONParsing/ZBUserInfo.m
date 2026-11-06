#import "ZBUserInfo.h"

// nil → NSNull conversion for JSON dictionaries
static id NSNullify(id _Nullable x) {
    return (x == nil || x == NSNull.null) ? NSNull.null : x;
}

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Private model interfaces

@interface ZBUserInfo (JSONConversion)
- (NSDictionary *)JSONDictionary;
@end

@interface ZBUser (JSONConversion)
- (NSDictionary *)JSONDictionary;
@end

#pragma mark - JSON serialization

NSData *_Nullable ZBUserInfoToData(ZBUserInfo *userInfo, NSError **error)
{
    @try {
        id json = [userInfo JSONDictionary];
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:kNilOptions error:error];
        return *error ? nil : data;
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:@"JSONSerialization" code:-1 userInfo:@{ @"exception": exception }];
        return nil;
    }
}

NSString *_Nullable ZBUserInfoToJSON(ZBUserInfo *userInfo, NSStringEncoding encoding, NSError **error)
{
    NSData *data = ZBUserInfoToData(userInfo, error);
    return data ? [[NSString alloc] initWithData:data encoding:encoding] : nil;
}

@implementation ZBUserInfo
+ (NSDictionary<NSString *, ZBJSONProperty *> *)properties
{
    static NSDictionary<NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"items": ZBJSONArrayOf(@"items", [NSString class]),
            @"user": ZBJSONObject(@"user", [ZBUser class]),
            @"error": ZBJSONString(@"error"),
        };
    }
    return properties;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBJSONPropertyNames(ZBUserInfo.properties)] mutableCopy];

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"user": NSNullify([_user JSONDictionary]),
    }];

    return dict;
}

- (NSData *_Nullable)toData:(NSError *_Nullable *)error
{
    return ZBUserInfoToData(self, error);
}

- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error
{
    return ZBUserInfoToJSON(self, encoding, error);
}
@end

@implementation ZBUser
+ (NSDictionary<NSString *, ZBJSONProperty *> *)properties
{
    static NSDictionary<NSString *, ZBJSONProperty *> *properties;
    if (!properties) {
        properties = @{
            @"name": ZBJSONString(@"name"),
            @"email": ZBJSONString(@"email")
        };
    }
    return properties;
}

- (NSDictionary *)JSONDictionary
{
    return [self dictionaryWithValuesForKeys:ZBJSONPropertyNames(ZBUser.properties)];
}
@end

NS_ASSUME_NONNULL_END
