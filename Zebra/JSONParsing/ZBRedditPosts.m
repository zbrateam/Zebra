#import "ZBRedditPosts.h"
#import "NSObject+Zebra.h"

// Shorthand for simple blocks
#define λ(decl, expr) (^(decl) { return (expr); })

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Private model interfaces

@interface ZBRedditPost (JSONConversion)
- (nullable instancetype)initWithJSONDictionary:(nullable NSDictionary *)dict;
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

@implementation ZBRedditPosts
+ (NSDictionary<NSString *, NSString *> *)properties
{
    return @{
        @"data": @"data"
    };
}

+ (nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error
{
    id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:error];
    return *error ? nil : [[ZBRedditPosts alloc] initWithJSONDictionary:json];
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        [self zbra_setValues:dict forProperties:self.class.properties];
        _data = map(_data, λ(id x, [[ZBRedditPost alloc] initWithJSONDictionary:x]));
    }
    return self;
}
@end

@implementation ZBRedditPost
+ (NSDictionary<NSString *, NSString *> *)properties
{
    return @{
        @"title": @"title",
        @"url": @"url",
        @"thumbnail": @"thumbnail",
        @"tags": @"tags"
    };
}

- (nullable instancetype)initWithJSONDictionary:(nullable NSDictionary *)dict
{
    if (!dict) {
        return nil;
    }
    self = [super init];
    if (self) {
        [self zbra_setValues:dict forProperties:self.class.properties];

        // Clean up Reddit encoding from string properties
        for (NSString *key in @[@"title", @"url", @"thumbnail"]) {
            NSString *text = [self valueForKey:key];
            if (text) {
                text = [text stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
                text = [text stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
                text = [text stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
                [self setValue:text forKey:key];
            }
        }
    }
    return self;
}
@end

NS_ASSUME_NONNULL_END
