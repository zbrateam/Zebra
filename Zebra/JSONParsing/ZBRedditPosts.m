#import "ZBRedditPosts.h"
#import "NSObject+Zebra.h"

// Shorthand for simple blocks
#define λ(decl, expr) (^(decl) { return (expr); })

// nil → NSNull conversion for JSON dictionaries
static id NSNullify(id _Nullable x) {
    return (x == nil || x == NSNull.null) ? NSNull.null : x;
}

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Private model interfaces

@interface ZBRedditPosts (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBRedditPostsData (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBChild (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBChildData (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBResizedIcon (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBPreview (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBImage (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBMediaMetadatum (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBMediaSource (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

static id map(id collection, id (^f)(id value)) {
    id result = nil;
    if ([collection isKindOfClass:NSArray.class]) {
        result = [NSMutableArray arrayWithCapacity:[(NSArray *)collection count]];
        for (id x in collection) [result addObject:f(x)];
    } else if ([collection isKindOfClass:NSDictionary.class]) {
        result = [NSMutableDictionary dictionaryWithCapacity:[(NSArray *)collection count]];
        for (id key in collection) [result setObject:f([collection objectForKey:key]) forKey:key];
    }
    return result;
}

#pragma mark - JSON serialization

ZBRedditPosts *_Nullable ZBRedditPostsFromData(NSData *data, NSError **error)
{
    @try {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
        return *error ? nil : [ZBRedditPosts fromJSONDictionary:json];
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:@"JSONSerialization" code:-1 userInfo:@{ @"exception": exception }];
        return nil;
    }
}

ZBRedditPosts *_Nullable ZBRedditPostsFromJSON(NSString *json, NSStringEncoding encoding, NSError **error)
{
    return ZBRedditPostsFromData([json dataUsingEncoding:encoding], error);
}

NSData *_Nullable ZBRedditPostsToData(ZBRedditPosts *redditPosts, NSError **error)
{
    @try {
        id json = [redditPosts JSONDictionary];
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:kNilOptions error:error];
        return *error ? nil : data;
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:@"JSONSerialization" code:-1 userInfo:@{ @"exception": exception }];
        return nil;
    }
}

NSString *_Nullable ZBRedditPostsToJSON(ZBRedditPosts *redditPosts, NSStringEncoding encoding, NSError **error)
{
    NSData *data = ZBRedditPostsToData(redditPosts, error);
    return data ? [[NSString alloc] initWithData:data encoding:encoding] : nil;
}

@implementation ZBRedditPosts
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"data": @"data",
    };
}

+ (_Nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error
{
    return ZBRedditPostsFromData(data, error);
}

+ (_Nullable instancetype)fromJSON:(NSString *)json encoding:(NSStringEncoding)encoding error:(NSError *_Nullable *)error
{
    return ZBRedditPostsFromJSON(json, encoding, error);
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBRedditPosts alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self zbra_setValues:dict forProperties:self.class.properties];
        _data = [ZBRedditPostsData fromJSONDictionary:(id)_data];
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBRedditPosts.properties.allValues] mutableCopy];

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"data": NSNullify([_data JSONDictionary]),
    }];

    return dict;
}

- (NSData *_Nullable)toData:(NSError *_Nullable *)error
{
    return ZBRedditPostsToData(self, error);
}

- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error
{
    return ZBRedditPostsToJSON(self, encoding, error);
}
@end

@implementation ZBRedditPostsData
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"children": @"children",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBRedditPostsData alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self zbra_setValues:dict forProperties:self.class.properties];
        _children = map(_children, λ(id x, [ZBChild fromJSONDictionary:x]));
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBRedditPostsData.properties.allValues] mutableCopy];

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"children": NSNullify(map(_children, λ(id x, [x JSONDictionary]))),
    }];

    return dict;
}
@end

@implementation ZBChild
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"data": @"data",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBChild alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self zbra_setValues:dict forProperties:self.class.properties];
        _data = [ZBChildData fromJSONDictionary:(id)_data];
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBChild.properties.allValues] mutableCopy];

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"data": NSNullify([_data JSONDictionary]),
    }];

    return dict;
}
@end

@implementation ZBChildData
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"id": @"identifier",
        @"created_utc": @"created",
        @"title": @"title",
        @"link_flair_css_class": @"linkFlairCSSClass",
        @"url": @"url",
        @"thumbnail": @"thumbnail",
        @"preview": @"preview",
        @"media_metadata": @"mediaMetadata"
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBChildData alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self zbra_setValues:dict forProperties:self.class.properties];
        _preview = [ZBPreview fromJSONDictionary:(id)_preview];
        _mediaMetadata = map(_mediaMetadata, λ(id x, [ZBMediaMetadatum fromJSONDictionary:x]));
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBChildData.properties.allValues] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBChildData.properties) {
        id propertyName = ZBChildData.properties[jsonName];
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"preview": NSNullify([_preview JSONDictionary]),
        @"media_metadata": NSNullify(map(_mediaMetadata, λ(id x, [x JSONDictionary]))),
    }];

    return dict;
}
@end

@implementation ZBResizedIcon
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"url": @"url",
        @"width": @"width",
        @"height": @"height",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBResizedIcon alloc] initWithJSONDictionary:dict] : nil;
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
    return [self dictionaryWithValuesForKeys:ZBResizedIcon.properties.allValues];
}
@end

@implementation ZBPreview
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"images": @"images",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBPreview alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self zbra_setValues:dict forProperties:self.class.properties];
        _images = map(_images, λ(id x, [ZBImage fromJSONDictionary:x]));
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBPreview.properties.allValues] mutableCopy];

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"images": NSNullify(map(_images, λ(id x, [x JSONDictionary]))),
    }];

    return dict;
}
@end

@implementation ZBImage
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"source": @"source",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBImage alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self zbra_setValues:dict forProperties:self.class.properties];
        _source = [ZBResizedIcon fromJSONDictionary:(id)_source];
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBImage.properties.allValues] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBImage.properties) {
        id propertyName = ZBImage.properties[jsonName];
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"source": NSNullify([_source JSONDictionary]),
    }];

    return dict;
}
@end

@implementation ZBMediaMetadatum
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"e": @"type",
        @"s": @"source",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBMediaMetadatum alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self zbra_setValues:dict forProperties:self.class.properties];
        _source = [ZBMediaSource fromJSONDictionary:(id)_source];
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBImage.properties.allValues] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBImage.properties) {
        id propertyName = ZBImage.properties[jsonName];
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"source": NSNullify([_source JSONDictionary]),
    }];

    return dict;
}
@end

@implementation ZBMediaSource
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"u": @"url",
        @"x": @"width",
        @"y": @"height",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBMediaSource alloc] initWithJSONDictionary:dict] : nil;
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
    return [self dictionaryWithValuesForKeys:ZBMediaSource.properties.allValues];
}
@end

NS_ASSUME_NONNULL_END
