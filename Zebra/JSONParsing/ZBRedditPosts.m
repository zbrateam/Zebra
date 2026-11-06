#import "ZBRedditPosts.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ZBRedditPosts
+ (NSDictionary<NSString *, ZBJSONProperty *> *)properties
{
    return @{
        @"data": ZBJSONArrayOf(@"data", [ZBRedditPost class])
    };
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

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    self = [super initWithJSONDictionary:dict];
    if (self) {
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
