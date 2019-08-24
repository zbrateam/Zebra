#import "ZBRedditPosts.h"

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

@interface ZBAllAwarding (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBResizedIcon (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBFlairRichtext (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBGildings (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBMedia (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBOembed (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBRedditVideo (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBMediaEmbed (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBMediaMetadatum (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

@interface ZBS (JSONConversion)
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

@interface ZBVariants (JSONConversion)
+ (instancetype)fromJSONDictionary:(NSDictionary *)dict;
- (NSDictionary *)JSONDictionary;
@end

// These enum-like reference types are needed so that enum
// values can be contained by NSArray and NSDictionary.

@implementation ZBAuthorFlairCSSClass
+ (NSDictionary<NSString *, ZBAuthorFlairCSSClass *> *)values
{
    static NSDictionary<NSString *, ZBAuthorFlairCSSClass *> *values;
    return values = values ? values : @{
        @"flair-default": [[ZBAuthorFlairCSSClass alloc] initWithValue:@"flair-default"],
        @"flair-verified": [[ZBAuthorFlairCSSClass alloc] initWithValue:@"flair-verified"],
    };
}

+ (ZBAuthorFlairCSSClass *)flairDefault { return ZBAuthorFlairCSSClass.values[@"flair-default"]; }
+ (ZBAuthorFlairCSSClass *)flairVerified { return ZBAuthorFlairCSSClass.values[@"flair-verified"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBAuthorFlairCSSClass.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
@end

@implementation ZBAuthorFlairType
+ (NSDictionary<NSString *, ZBAuthorFlairType *> *)values
{
    static NSDictionary<NSString *, ZBAuthorFlairType *> *values;
    return values = values ? values : @{
        @"richtext": [[ZBAuthorFlairType alloc] initWithValue:@"richtext"],
        @"text": [[ZBAuthorFlairType alloc] initWithValue:@"text"],
    };
}

+ (ZBAuthorFlairType *)richtext { return ZBAuthorFlairType.values[@"richtext"]; }
+ (ZBAuthorFlairType *)text { return ZBAuthorFlairType.values[@"text"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBAuthorFlairType.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
@end

@implementation ZBFlairTextColor
+ (NSDictionary<NSString *, ZBFlairTextColor *> *)values
{
    static NSDictionary<NSString *, ZBFlairTextColor *> *values;
    return values = values ? values : @{
        @"dark": [[ZBFlairTextColor alloc] initWithValue:@"dark"],
    };
}

+ (ZBFlairTextColor *)dark { return ZBFlairTextColor.values[@"dark"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBFlairTextColor.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
@end

@implementation ZBLinkFlairBackgroundColor
+ (NSDictionary<NSString *, ZBLinkFlairBackgroundColor *> *)values
{
    static NSDictionary<NSString *, ZBLinkFlairBackgroundColor *> *values;
    return values = values ? values : @{
        @"": [[ZBLinkFlairBackgroundColor alloc] initWithValue:@""],
        @"#ff2d55": [[ZBLinkFlairBackgroundColor alloc] initWithValue:@"#ff2d55"],
        @"#81bb81": [[ZBLinkFlairBackgroundColor alloc] initWithValue:@"#81bb81"],
    };
}

+ (ZBLinkFlairBackgroundColor *)empty { return ZBLinkFlairBackgroundColor.values[@""]; }
+ (ZBLinkFlairBackgroundColor *)ff2D55 { return ZBLinkFlairBackgroundColor.values[@"#ff2d55"]; }
+ (ZBLinkFlairBackgroundColor *)the81Bb81 { return ZBLinkFlairBackgroundColor.values[@"#81bb81"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBLinkFlairBackgroundColor.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
@end

@implementation ZBE
+ (NSDictionary<NSString *, ZBE *> *)values
{
    static NSDictionary<NSString *, ZBE *> *values;
    return values = values ? values : @{
        @"Image": [[ZBE alloc] initWithValue:@"Image"],
    };
}

+ (ZBE *)image { return ZBE.values[@"Image"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBE.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
@end

@implementation ZBM
+ (NSDictionary<NSString *, ZBM *> *)values
{
    static NSDictionary<NSString *, ZBM *> *values;
    return values = values ? values : @{
        @"image/jpg": [[ZBM alloc] initWithValue:@"image/jpg"],
        @"image/png": [[ZBM alloc] initWithValue:@"image/png"],
    };
}

+ (ZBM *)imageJpg { return ZBM.values[@"image/jpg"]; }
+ (ZBM *)imagePNG { return ZBM.values[@"image/png"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBM.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
@end

@implementation ZBStatus
+ (NSDictionary<NSString *, ZBStatus *> *)values
{
    static NSDictionary<NSString *, ZBStatus *> *values;
    return values = values ? values : @{
        @"valid": [[ZBStatus alloc] initWithValue:@"valid"],
    };
}

+ (ZBStatus *)valid { return ZBStatus.values[@"valid"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBStatus.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
@end

@implementation ZBWhitelistStatus
+ (NSDictionary<NSString *, ZBWhitelistStatus *> *)values
{
    static NSDictionary<NSString *, ZBWhitelistStatus *> *values;
    return values = values ? values : @{
        @"all_ads": [[ZBWhitelistStatus alloc] initWithValue:@"all_ads"],
    };
}

+ (ZBWhitelistStatus *)allAds { return ZBWhitelistStatus.values[@"all_ads"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBWhitelistStatus.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
@end

@implementation ZBSubreddit
+ (NSDictionary<NSString *, ZBSubreddit *> *)values
{
    static NSDictionary<NSString *, ZBSubreddit *> *values;
    return values = values ? values : @{
        @"jailbreak": [[ZBSubreddit alloc] initWithValue:@"jailbreak"],
    };
}

+ (ZBSubreddit *)jailbreak { return ZBSubreddit.values[@"jailbreak"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBSubreddit.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
@end

@implementation ZBSubredditID
+ (NSDictionary<NSString *, ZBSubredditID *> *)values
{
    static NSDictionary<NSString *, ZBSubredditID *> *values;
    return values = values ? values : @{
        @"t5_2r8c5": [[ZBSubredditID alloc] initWithValue:@"t5_2r8c5"],
    };
}

+ (ZBSubredditID *)t52R8C5 { return ZBSubredditID.values[@"t5_2r8c5"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBSubredditID.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
@end

@implementation ZBSubredditNamePrefixed
+ (NSDictionary<NSString *, ZBSubredditNamePrefixed *> *)values
{
    static NSDictionary<NSString *, ZBSubredditNamePrefixed *> *values;
    return values = values ? values : @{
        @"r/jailbreak": [[ZBSubredditNamePrefixed alloc] initWithValue:@"r/jailbreak"],
    };
}

+ (ZBSubredditNamePrefixed *)rJailbreak { return ZBSubredditNamePrefixed.values[@"r/jailbreak"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBSubredditNamePrefixed.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
@end

@implementation ZBSubredditType
+ (NSDictionary<NSString *, ZBSubredditType *> *)values
{
    static NSDictionary<NSString *, ZBSubredditType *> *values;
    return values = values ? values : @{
        @"public": [[ZBSubredditType alloc] initWithValue:@"public"],
    };
}

+ (ZBSubredditType *)public { return ZBSubredditType.values[@"public"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBSubredditType.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
@end

@implementation ZBKind
+ (NSDictionary<NSString *, ZBKind *> *)values
{
    static NSDictionary<NSString *, ZBKind *> *values;
    return values = values ? values : @{
        @"t3": [[ZBKind alloc] initWithValue:@"t3"],
    };
}

+ (ZBKind *)t3 { return ZBKind.values[@"t3"]; }

+ (instancetype _Nullable)withValue:(NSString *)value
{
    return ZBKind.values[value];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) _value = value;
    return self;
}

- (NSUInteger)hash { return _value.hash; }
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
        @"kind": @"kind",
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
        [self setValuesForKeysWithDictionary:dict];
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
        @"modhash": @"modhash",
        @"dist": @"dist",
        @"children": @"children",
        @"after": @"after",
        @"before": @"before",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBRedditPostsData alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
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
        @"kind": @"kind",
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
        [self setValuesForKeysWithDictionary:dict];
        _kind = [ZBKind withValue:(id)_kind];
        _data = [ZBChildData fromJSONDictionary:(id)_data];
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBChild.properties.allValues] mutableCopy];

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"kind": NSNullify([_kind value]),
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
        @"approved_at_utc": @"approvedAtUTC",
        @"subreddit": @"subreddit",
        @"selftext": @"selftext",
        @"author_fullname": @"authorFullname",
        @"saved": @"saved",
        @"mod_reason_title": @"modReasonTitle",
        @"gilded": @"gilded",
        @"clicked": @"clicked",
        @"title": @"title",
        @"link_flair_richtext": @"linkFlairRichtext",
        @"subreddit_name_prefixed": @"subredditNamePrefixed",
        @"hidden": @"hidden",
        @"pwls": @"pwls",
        @"link_flair_css_class": @"linkFlairCSSClass",
        @"downs": @"downs",
        @"thumbnail_height": @"thumbnailHeight",
        @"hide_score": @"hideScore",
        @"name": @"name",
        @"quarantine": @"quarantine",
        @"link_flair_text_color": @"linkFlairTextColor",
        @"author_flair_background_color": @"authorFlairBackgroundColor",
        @"subreddit_type": @"subredditType",
        @"ups": @"ups",
        @"total_awards_received": @"totalAwardsReceived",
        @"media_embed": @"mediaEmbed",
        @"thumbnail_width": @"thumbnailWidth",
        @"author_flair_template_id": @"authorFlairTemplateID",
        @"is_original_content": @"isOriginalContent",
        @"user_reports": @"userReports",
        @"secure_media": @"secureMedia",
        @"is_reddit_media_domain": @"isRedditMediaDomain",
        @"is_meta": @"isMeta",
        @"category": @"category",
        @"secure_media_embed": @"secureMediaEmbed",
        @"link_flair_text": @"linkFlairText",
        @"can_mod_post": @"canModPost",
        @"score": @"score",
        @"approved_by": @"approvedBy",
        @"thumbnail": @"thumbnail",
        @"author_cakeday": @"authorCakeday",
        @"edited": @"edited",
        @"author_flair_css_class": @"authorFlairCSSClass",
        @"author_flair_richtext": @"authorFlairRichtext",
        @"gildings": @"gildings",
        @"content_categories": @"contentCategories",
        @"is_self": @"isSelf",
        @"mod_note": @"modNote",
        @"created": @"created",
        @"link_flair_type": @"linkFlairType",
        @"wls": @"wls",
        @"banned_by": @"bannedBy",
        @"author_flair_type": @"authorFlairType",
        @"domain": @"domain",
        @"allow_live_comments": @"allowLiveComments",
        @"selftext_html": @"selftextHTML",
        @"likes": @"likes",
        @"suggested_sort": @"suggestedSort",
        @"banned_at_utc": @"bannedAtUTC",
        @"view_count": @"viewCount",
        @"archived": @"archived",
        @"no_follow": @"noFollow",
        @"is_crosspostable": @"isCrosspostable",
        @"pinned": @"pinned",
        @"over_18": @"over18",
        @"all_awardings": @"allAwardings",
        @"media_only": @"mediaOnly",
        @"link_flair_template_id": @"linkFlairTemplateID",
        @"can_gild": @"canGild",
        @"spoiler": @"spoiler",
        @"locked": @"locked",
        @"author_flair_text": @"authorFlairText",
        @"visited": @"visited",
        @"num_reports": @"numReports",
        @"distinguished": @"distinguished",
        @"subreddit_id": @"subredditID",
        @"mod_reason_by": @"modReasonBy",
        @"removal_reason": @"removalReason",
        @"link_flair_background_color": @"linkFlairBackgroundColor",
        @"id": @"identifier",
        @"is_robot_indexable": @"isRobotIndexable",
        @"report_reasons": @"reportReasons",
        @"author": @"author",
        @"num_crossposts": @"numCrossposts",
        @"num_comments": @"numComments",
        @"send_replies": @"sendReplies",
        @"whitelist_status": @"whitelistStatus",
        @"contest_mode": @"contestMode",
        @"mod_reports": @"modReports",
        @"author_patreon_flair": @"authorPatreonFlair",
        @"author_flair_text_color": @"authorFlairTextColor",
        @"permalink": @"permalink",
        @"parent_whitelist_status": @"parentWhitelistStatus",
        @"stickied": @"stickied",
        @"url": @"url",
        @"subreddit_subscribers": @"subredditSubscribers",
        @"created_utc": @"createdUTC",
        @"discussion_type": @"discussionType",
        @"media": @"media",
        @"is_video": @"isVideo",
        @"post_hint": @"postHint",
        @"preview": @"preview",
        @"media_metadata": @"mediaMetadata",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBChildData alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
        _subreddit = [ZBSubreddit withValue:(id)_subreddit];
        _linkFlairRichtext = map(_linkFlairRichtext, λ(id x, [ZBFlairRichtext fromJSONDictionary:x]));
        _subredditNamePrefixed = [ZBSubredditNamePrefixed withValue:(id)_subredditNamePrefixed];
        _linkFlairTextColor = [ZBFlairTextColor withValue:(id)_linkFlairTextColor];
        _subredditType = [ZBSubredditType withValue:(id)_subredditType];
        _mediaEmbed = [ZBMediaEmbed fromJSONDictionary:(id)_mediaEmbed];
        _secureMedia = [ZBMedia fromJSONDictionary:(id)_secureMedia];
        _secureMediaEmbed = [ZBMediaEmbed fromJSONDictionary:(id)_secureMediaEmbed];
        _authorFlairCSSClass = [ZBAuthorFlairCSSClass withValue:(id)_authorFlairCSSClass];
        _authorFlairRichtext = map(_authorFlairRichtext, λ(id x, [ZBFlairRichtext fromJSONDictionary:x]));
        _gildings = [ZBGildings fromJSONDictionary:(id)_gildings];
        _linkFlairType = [ZBAuthorFlairType withValue:(id)_linkFlairType];
        _authorFlairType = [ZBAuthorFlairType withValue:(id)_authorFlairType];
        _allAwardings = map(_allAwardings, λ(id x, [ZBAllAwarding fromJSONDictionary:x]));
        _subredditID = [ZBSubredditID withValue:(id)_subredditID];
        _linkFlairBackgroundColor = [ZBLinkFlairBackgroundColor withValue:(id)_linkFlairBackgroundColor];
        _whitelistStatus = [ZBWhitelistStatus withValue:(id)_whitelistStatus];
        _authorFlairTextColor = [ZBFlairTextColor withValue:(id)_authorFlairTextColor];
        _parentWhitelistStatus = [ZBWhitelistStatus withValue:(id)_parentWhitelistStatus];
        _media = [ZBMedia fromJSONDictionary:(id)_media];
        _preview = [ZBPreview fromJSONDictionary:(id)_preview];
        _mediaMetadata = map(_mediaMetadata, λ(id x, [ZBMediaMetadatum fromJSONDictionary:x]));
    }
    return self;
}

- (void)setValue:(nullable id)value forKey:(NSString *)key
{
    id resolved = ZBChildData.properties[key];
    if (resolved) [super setValue:value forKey:resolved];
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
        @"subreddit": NSNullify([_subreddit value]),
        @"link_flair_richtext": NSNullify(map(_linkFlairRichtext, λ(id x, [x JSONDictionary]))),
        @"subreddit_name_prefixed": NSNullify([_subredditNamePrefixed value]),
        @"link_flair_text_color": NSNullify([_linkFlairTextColor value]),
        @"subreddit_type": NSNullify([_subredditType value]),
        @"media_embed": NSNullify([_mediaEmbed JSONDictionary]),
        @"secure_media": NSNullify([_secureMedia JSONDictionary]),
        @"secure_media_embed": NSNullify([_secureMediaEmbed JSONDictionary]),
        @"author_flair_css_class": NSNullify([_authorFlairCSSClass value]),
        @"author_flair_richtext": NSNullify(map(_authorFlairRichtext, λ(id x, [x JSONDictionary]))),
        @"gildings": NSNullify([_gildings JSONDictionary]),
        @"link_flair_type": NSNullify([_linkFlairType value]),
        @"author_flair_type": NSNullify([_authorFlairType value]),
        @"all_awardings": NSNullify(map(_allAwardings, λ(id x, [x JSONDictionary]))),
        @"subreddit_id": NSNullify([_subredditID value]),
        @"link_flair_background_color": NSNullify([_linkFlairBackgroundColor value]),
        @"whitelist_status": NSNullify([_whitelistStatus value]),
        @"author_flair_text_color": NSNullify([_authorFlairTextColor value]),
        @"parent_whitelist_status": NSNullify([_parentWhitelistStatus value]),
        @"media": NSNullify([_media JSONDictionary]),
        @"preview": NSNullify([_preview JSONDictionary]),
        @"media_metadata": NSNullify(map(_mediaMetadata, λ(id x, [x JSONDictionary]))),
    }];

    return dict;
}
@end

@implementation ZBAllAwarding
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"is_enabled": @"isEnabled",
        @"count": @"count",
        @"subreddit_id": @"subredditID",
        @"description": @"theDescription",
        @"coin_reward": @"coinReward",
        @"icon_width": @"iconWidth",
        @"icon_url": @"iconURL",
        @"days_of_premium": @"daysOfPremium",
        @"id": @"identifier",
        @"icon_height": @"iconHeight",
        @"resized_icons": @"resizedIcons",
        @"days_of_drip_extension": @"daysOfDripExtension",
        @"award_type": @"awardType",
        @"coin_price": @"coinPrice",
        @"subreddit_coin_reward": @"subredditCoinReward",
        @"name": @"name",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBAllAwarding alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
        _resizedIcons = map(_resizedIcons, λ(id x, [ZBResizedIcon fromJSONDictionary:x]));
    }
    return self;
}

- (void)setValue:(nullable id)value forKey:(NSString *)key
{
    id resolved = ZBAllAwarding.properties[key];
    if (resolved) [super setValue:value forKey:resolved];
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBAllAwarding.properties.allValues] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBAllAwarding.properties) {
        id propertyName = ZBAllAwarding.properties[jsonName];
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"resized_icons": NSNullify(map(_resizedIcons, λ(id x, [x JSONDictionary]))),
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
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    return [self dictionaryWithValuesForKeys:ZBResizedIcon.properties.allValues];
}
@end

@implementation ZBFlairRichtext
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"e": @"e",
        @"t": @"t",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBFlairRichtext alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
        _e = [ZBAuthorFlairType withValue:(id)_e];
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBFlairRichtext.properties.allValues] mutableCopy];

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"e": NSNullify([_e value]),
    }];

    return dict;
}
@end

@implementation ZBGildings
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"gid_1": @"gid1",
        @"gid_2": @"gid2",
        @"gid_3": @"gid3",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBGildings alloc] initWithJSONDictionary:dict] : nil;
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
    id resolved = ZBGildings.properties[key];
    if (resolved) [super setValue:value forKey:resolved];
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBGildings.properties.allValues] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBGildings.properties) {
        id propertyName = ZBGildings.properties[jsonName];
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    return dict;
}
@end

@implementation ZBMedia
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"reddit_video": @"redditVideo",
        @"oembed": @"oembed",
        @"type": @"type",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBMedia alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
        _redditVideo = [ZBRedditVideo fromJSONDictionary:(id)_redditVideo];
        _oembed = [ZBOembed fromJSONDictionary:(id)_oembed];
    }
    return self;
}

- (void)setValue:(nullable id)value forKey:(NSString *)key
{
    id resolved = ZBMedia.properties[key];
    if (resolved) [super setValue:value forKey:resolved];
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBMedia.properties.allValues] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBMedia.properties) {
        id propertyName = ZBMedia.properties[jsonName];
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"reddit_video": NSNullify([_redditVideo JSONDictionary]),
        @"oembed": NSNullify([_oembed JSONDictionary]),
    }];

    return dict;
}
@end

@implementation ZBOembed
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"provider_url": @"providerURL",
        @"url": @"url",
        @"html": @"html",
        @"author_name": @"authorName",
        @"height": @"height",
        @"width": @"width",
        @"version": @"version",
        @"author_url": @"authorURL",
        @"provider_name": @"providerName",
        @"cache_age": @"cacheAge",
        @"type": @"type",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBOembed alloc] initWithJSONDictionary:dict] : nil;
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
    id resolved = ZBOembed.properties[key];
    if (resolved) [super setValue:value forKey:resolved];
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBOembed.properties.allValues] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBOembed.properties) {
        id propertyName = ZBOembed.properties[jsonName];
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    return dict;
}
@end

@implementation ZBRedditVideo
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"fallback_url": @"fallbackURL",
        @"height": @"height",
        @"width": @"width",
        @"scrubber_media_url": @"scrubberMediaURL",
        @"dash_url": @"dashURL",
        @"duration": @"duration",
        @"hls_url": @"hlsURL",
        @"is_gif": @"isGIF",
        @"transcoding_status": @"transcodingStatus",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBRedditVideo alloc] initWithJSONDictionary:dict] : nil;
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
    id resolved = ZBRedditVideo.properties[key];
    if (resolved) [super setValue:value forKey:resolved];
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBRedditVideo.properties.allValues] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBRedditVideo.properties) {
        id propertyName = ZBRedditVideo.properties[jsonName];
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    return dict;
}
@end

@implementation ZBMediaEmbed
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"content": @"content",
        @"width": @"width",
        @"scrolling": @"scrolling",
        @"height": @"height",
        @"media_domain_url": @"mediaDomainURL",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBMediaEmbed alloc] initWithJSONDictionary:dict] : nil;
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
    id resolved = ZBMediaEmbed.properties[key];
    if (resolved) [super setValue:value forKey:resolved];
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBMediaEmbed.properties.allValues] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBMediaEmbed.properties) {
        id propertyName = ZBMediaEmbed.properties[jsonName];
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    return dict;
}
@end

@implementation ZBMediaMetadatum
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"status": @"status",
        @"e": @"e",
        @"s": @"s",
        @"m": @"m",
        @"id": @"identifier",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBMediaMetadatum alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
        _status = [ZBStatus withValue:(id)_status];
        _e = [ZBE withValue:(id)_e];
        _s = [ZBS fromJSONDictionary:(id)_s];
        _m = [ZBM withValue:(id)_m];
    }
    return self;
}

- (void)setValue:(nullable id)value forKey:(NSString *)key
{
    id resolved = ZBMediaMetadatum.properties[key];
    if (resolved) [super setValue:value forKey:resolved];
}

- (NSDictionary *)JSONDictionary
{
    id dict = [[self dictionaryWithValuesForKeys:ZBMediaMetadatum.properties.allValues] mutableCopy];

    // Rewrite property names that differ in JSON
    for (id jsonName in ZBMediaMetadatum.properties) {
        id propertyName = ZBMediaMetadatum.properties[jsonName];
        if (![jsonName isEqualToString:propertyName]) {
            dict[jsonName] = dict[propertyName];
            [dict removeObjectForKey:propertyName];
        }
    }

    // Map values that need translation
    [dict addEntriesFromDictionary:@{
        @"status": NSNullify([_status value]),
        @"e": NSNullify([_e value]),
        @"s": NSNullify([_s JSONDictionary]),
        @"m": NSNullify([_m value]),
    }];

    return dict;
}
@end

@implementation ZBS
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"y": @"y",
        @"x": @"x",
        @"u": @"u",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBS alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    return [self dictionaryWithValuesForKeys:ZBS.properties.allValues];
}
@end

@implementation ZBPreview
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
        @"images": @"images",
        @"enabled": @"enabled",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBPreview alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
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
        @"resolutions": @"resolutions",
        @"variants": @"variants",
        @"id": @"identifier",
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBImage alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
        _source = [ZBResizedIcon fromJSONDictionary:(id)_source];
        _resolutions = map(_resolutions, λ(id x, [ZBResizedIcon fromJSONDictionary:x]));
        _variants = [ZBVariants fromJSONDictionary:(id)_variants];
    }
    return self;
}

- (void)setValue:(nullable id)value forKey:(NSString *)key
{
    id resolved = ZBImage.properties[key];
    if (resolved) [super setValue:value forKey:resolved];
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
        @"resolutions": NSNullify(map(_resolutions, λ(id x, [x JSONDictionary]))),
        @"variants": NSNullify([_variants JSONDictionary]),
    }];

    return dict;
}
@end

@implementation ZBVariants
+ (NSDictionary<NSString *, NSString *> *)properties
{
    static NSDictionary<NSString *, NSString *> *properties;
    return properties = properties ? properties : @{
    };
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict
{
    return dict ? [[ZBVariants alloc] initWithJSONDictionary:dict] : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (NSDictionary *)JSONDictionary
{
    return [self dictionaryWithValuesForKeys:ZBVariants.properties.allValues];
}
@end

NS_ASSUME_NONNULL_END
