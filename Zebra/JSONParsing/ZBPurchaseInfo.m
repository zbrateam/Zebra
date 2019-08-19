#import "ZBPurchaseInfo.h"

// Shorthand for simple blocks
#define λ(decl, expr) (^(decl) { return (expr); })

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Private model interfaces

@interface ZBPurchaseInfo (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

#pragma mark - JSON serialization

ZBPurchaseInfo *_Nullable ZBPurchaseInfoFromData(NSData *data, NSError **error)
{
    @try {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
        return *error ? nil : [ZBPurchaseInfo fromJSONDictionary:json];
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:@"JSONSerialization" code:-1 userInfo:@{ @"exception": exception }];
        return nil;
    }
}

ZBPurchaseInfo *_Nullable ZBPurchaseInfoFromJSON(NSString *json, NSStringEncoding encoding, NSError **error)
{
    return ZBPurchaseInfoFromData([json dataUsingEncoding:encoding], error);
}

NSData *_Nullable ZBPurchaseInfoToData(ZBPurchaseInfo *purchaseInfo, NSError **error)
{
    @try {
        id json = [purchaseInfo JSONDictionary];
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:kNilOptions error:error];
        return *error ? nil : data;
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:@"JSONSerialization" code:-1 userInfo:@{ @"exception": exception }];
        return nil;
    }
}

NSString *_Nullable ZBPurchaseInfoToJSON(ZBPurchaseInfo *purchaseInfo, NSStringEncoding encoding, NSError **error)
{
    NSData *data = ZBPurchaseInfoToData(purchaseInfo, error);
    return data ? [[NSString alloc] initWithData:data encoding:encoding] : nil;
}

@implementation ZBPurchaseInfo
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"price": @"price",
        @"purchased": @"purchased",
        @"available": @"available",
        @"error": @"error",
        @"recovery_url": @"recoveryURL",
    };
}

+ (_Nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error
{
    return ZBPurchaseInfoFromData(data, error);
}

+ (_Nullable instancetype)fromJSON:(NSString *)json encoding:(NSStringEncoding)encoding error:(NSError *_Nullable *)error
{
    return ZBPurchaseInfoFromJSON(json, encoding, error);
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBPurchaseInfo alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)setValue:(nullable id)value forKey:(NSString *)key
{
    id resolved = ZBPurchaseInfo.properties[key];
    if (resolved) [super setValue:value forKey:resolved];
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBPurchaseInfo.properties.allValues] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBPurchaseInfo.properties) {
        id propertyName = ZBPurchaseInfo.properties[jsonName];
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    return dict;
}

- (NSData *_Nullable)toData:(NSError *_Nullable *)error
{
    return ZBPurchaseInfoToData(self, error);
}

- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error
{
    return ZBPurchaseInfoToJSON(self, encoding, error);
}
@end

NS_ASSUME_NONNULL_END
