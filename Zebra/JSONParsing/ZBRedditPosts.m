#import "ZBRedditPosts.h"
#import "NSObject+Zebra.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Private model interfaces

@interface ZBRedditPost (JSONConversion) <ZBJSONDecodable>
+ (nullable instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (nullable instancetype)initWithJSONDictionary:(nullable NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@implementation ZBRedditPosts
+ (NSDictionary<NSString *, ZBJSONProperty *> *)properties
{
    return @{
        @"data": ZBJSONArrayOf(@"data", [ZBRedditPost class])
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
    }
    return self;
}
@end

@implementation ZBRedditPost
+ (NSDictionary<NSString *, ZBJSONProperty *> *)properties
{
    return @{
        @"title": ZBJSONString(@"title"),
        @"url": ZBJSONString(@"url"),
        @"thumbnail": ZBJSONString(@"thumbnail"),
        @"tags": ZBJSONString(@"tags")
    };
}

+ (nullable instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithJSONDictionary:dict];
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
