#import "ZBPurchaseInfo.h"
#import "NSObject+Zebra.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Private model interfaces

@interface ZBPurchaseInfo (JSONConversion) <ZBJSONDecodable>
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

NS_ASSUME_NONNULL_END

#pragma mark - JSON serialization

ZBPurchaseInfo *_Nullable ZBPurchaseInfoFromData(NSData *data, NSError **error) {
    @try {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
        return *error ? nil : [ZBPurchaseInfo fromJSONDictionary:json];
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:@"JSONSerialization" code:-1 userInfo:@{ @"exception": exception }];
        return nil;
    }
}

ZBPurchaseInfo *_Nullable ZBPurchaseInfoFromJSON(NSString *json, NSStringEncoding encoding, NSError **error) {
    return ZBPurchaseInfoFromData([json dataUsingEncoding:encoding], error);
}

NSData *_Nullable ZBPurchaseInfoToData(ZBPurchaseInfo *purchaseInfo, NSError **error) {
    @try {
        id json = [purchaseInfo JSONDictionary];
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:kNilOptions error:error];
        return *error ? nil : data;
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:@"JSONSerialization" code:-1 userInfo:@{ @"exception": exception }];
        return nil;
    }
}

NSString *_Nullable ZBPurchaseInfoToJSON(ZBPurchaseInfo *purchaseInfo, NSStringEncoding encoding, NSError **error) {
    NSData *data = ZBPurchaseInfoToData(purchaseInfo, error);
    return data ? [[NSString alloc] initWithData:data encoding:encoding] : nil;
}

@implementation ZBPurchaseInfo

+ (NSDictionary<NSString *, ZBJSONProperty *> *)properties {
    static NSDictionary<NSString *, ZBJSONProperty *> *properties;
    return properties = properties ? properties : @{
        @"price": ZBJSONString(@"price"),
        @"purchased": ZBJSONNumber(@"purchased"),
        @"available": ZBJSONNumber(@"available"),
        @"error": ZBJSONString(@"error"),
        @"recovery_url": ZBJSONString(@"recoveryURL"),
    };
}

+ (_Nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error {
    return ZBPurchaseInfoFromData(data, error);
}

+ (_Nullable instancetype)fromJSON:(NSString *)json encoding:(NSStringEncoding)encoding error:(NSError *_Nullable *)error {
    return ZBPurchaseInfoFromJSON(json, encoding, error);
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict {
    return dict ? [[ZBPurchaseInfo alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict {
    self = [super init];
    
    if (self) {
        [self zbra_setValues:dict forProperties:self.class.properties];
    }
    
    return self;
}

- (NSDictionary *)JSONDictionary {
    id dict = [[self dictionaryWithValuesForKeys:ZBJSONPropertyNames(ZBPurchaseInfo.properties)] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBPurchaseInfo.properties) {
        NSString *propertyName = ZBPurchaseInfo.properties[jsonName].propertyName;
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    return dict;
}

- (NSData *_Nullable)toData:(NSError *_Nullable *)error {
    return ZBPurchaseInfoToData(self, error);
}

- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error {
    return ZBPurchaseInfoToJSON(self, encoding, error);
}

@end
