// To parse this JSON:
//
//   NSError *error;
//   ZBRedditPosts *redditPosts = [ZBRedditPosts fromJSON:json encoding:NSUTF8Encoding error:&error];

#import <Foundation/Foundation.h>

@class ZBRedditPosts;
@class ZBRedditPostsData;
@class ZBChild;
@class ZBChildData;
@class ZBAllAwarding;
@class ZBResizedIcon;
@class ZBAuthorFlairCSSClass;
@class ZBFlairRichtext;
@class ZBAuthorFlairType;
@class ZBFlairTextColor;
@class ZBGildings;
@class ZBLinkFlairBackgroundColor;
@class ZBMedia;
@class ZBOembed;
@class ZBRedditVideo;
@class ZBMediaEmbed;
@class ZBMediaMetadatum;
@class ZBE;
@class ZBM;
@class ZBS;
@class ZBStatus;
@class ZBWhitelistStatus;
@class ZBPreview;
@class ZBImage;
@class ZBVariants;
@class ZBSubreddit;
@class ZBSubredditID;
@class ZBSubredditNamePrefixed;
@class ZBSubredditType;
@class ZBKind;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Boxed enums

@interface ZBAuthorFlairCSSClass : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBAuthorFlairCSSClass *)flairDefault;
+ (ZBAuthorFlairCSSClass *)flairVerified;
@end

@interface ZBAuthorFlairType : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBAuthorFlairType *)richtext;
+ (ZBAuthorFlairType *)text;
@end

@interface ZBFlairTextColor : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBFlairTextColor *)dark;
@end

@interface ZBLinkFlairBackgroundColor : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBLinkFlairBackgroundColor *)empty;
+ (ZBLinkFlairBackgroundColor *)ff2D55;
+ (ZBLinkFlairBackgroundColor *)the81Bb81;
@end

@interface ZBE : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBE *)image;
@end

@interface ZBM : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBM *)imageJpg;
+ (ZBM *)imagePNG;
@end

@interface ZBStatus : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBStatus *)valid;
@end

@interface ZBWhitelistStatus : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBWhitelistStatus *)allAds;
@end

@interface ZBSubreddit : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBSubreddit *)jailbreak;
@end

@interface ZBSubredditID : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBSubredditID *)t52R8C5;
@end

@interface ZBSubredditNamePrefixed : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBSubredditNamePrefixed *)rJailbreak;
@end

@interface ZBSubredditType : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBSubredditType *)public;
@end

@interface ZBKind : NSObject
@property (nonatomic, readonly, copy) NSString *value;
+ (instancetype _Nullable)withValue:(NSString *)value;
+ (ZBKind *)t3;
@end

#pragma mark - Object interfaces

@interface ZBRedditPosts : NSObject
@property (nonatomic, nullable, copy)   NSString *kind;
@property (nonatomic, nullable, strong) ZBRedditPostsData *data;

+ (_Nullable instancetype)fromJSON:(NSString *)json encoding:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
+ (_Nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error;
- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
- (NSData *_Nullable)toData:(NSError *_Nullable *)error;
@end

@interface ZBRedditPostsData : NSObject
@property (nonatomic, nullable, copy)   NSString *modhash;
@property (nonatomic, nullable, strong) NSNumber *dist;
@property (nonatomic, nullable, copy)   NSArray<ZBChild *> *children;
@property (nonatomic, nullable, copy)   NSString *after;
@property (nonatomic, nullable, copy)   id before;
@end

@interface ZBChild : NSObject
@property (nonatomic, nullable, assign) ZBKind *kind;
@property (nonatomic, nullable, strong) ZBChildData *data;
@end

@interface ZBChildData : NSObject
@property (nonatomic, nullable, copy)   id approvedAtUTC;
@property (nonatomic, nullable, assign) ZBSubreddit *subreddit;
@property (nonatomic, nullable, copy)   NSString *selftext;
@property (nonatomic, nullable, copy)   NSString *authorFullname;
@property (nonatomic, nullable, strong) NSNumber *saved;
@property (nonatomic, nullable, copy)   id modReasonTitle;
@property (nonatomic, nullable, strong) NSNumber *gilded;
@property (nonatomic, nullable, strong) NSNumber *clicked;
@property (nonatomic, nullable, copy)   NSString *title;
@property (nonatomic, nullable, copy)   NSArray<ZBFlairRichtext *> *linkFlairRichtext;
@property (nonatomic, nullable, assign) ZBSubredditNamePrefixed *subredditNamePrefixed;
@property (nonatomic, nullable, strong) NSNumber *hidden;
@property (nonatomic, nullable, strong) NSNumber *pwls;
@property (nonatomic, nullable, copy)   NSString *linkFlairCSSClass;
@property (nonatomic, nullable, strong) NSNumber *downs;
@property (nonatomic, nullable, strong) NSNumber *thumbnailHeight;
@property (nonatomic, nullable, strong) NSNumber *hideScore;
@property (nonatomic, nullable, copy)   NSString *name;
@property (nonatomic, nullable, strong) NSNumber *quarantine;
@property (nonatomic, nullable, assign) ZBFlairTextColor *linkFlairTextColor;
@property (nonatomic, nullable, copy)   NSString *authorFlairBackgroundColor;
@property (nonatomic, nullable, assign) ZBSubredditType *subredditType;
@property (nonatomic, nullable, strong) NSNumber *ups;
@property (nonatomic, nullable, strong) NSNumber *totalAwardsReceived;
@property (nonatomic, nullable, strong) ZBMediaEmbed *mediaEmbed;
@property (nonatomic, nullable, strong) NSNumber *thumbnailWidth;
@property (nonatomic, nullable, copy)   NSString *authorFlairTemplateID;
@property (nonatomic, nullable, strong) NSNumber *isOriginalContent;
@property (nonatomic, nullable, copy)   NSArray *userReports;
@property (nonatomic, nullable, strong) ZBMedia *secureMedia;
@property (nonatomic, nullable, strong) NSNumber *isRedditMediaDomain;
@property (nonatomic, nullable, strong) NSNumber *isMeta;
@property (nonatomic, nullable, copy)   id category;
@property (nonatomic, nullable, strong) ZBMediaEmbed *secureMediaEmbed;
@property (nonatomic, nullable, copy)   NSString *linkFlairText;
@property (nonatomic, nullable, strong) NSNumber *canModPost;
@property (nonatomic, nullable, strong) NSNumber *score;
@property (nonatomic, nullable, copy)   id approvedBy;
@property (nonatomic, nullable, copy)   NSString *thumbnail;
@property (nonatomic, nullable, strong) NSNumber *authorCakeday;
@property (nonatomic, nullable, copy)   id edited;
@property (nonatomic, nullable, assign) ZBAuthorFlairCSSClass *authorFlairCSSClass;
@property (nonatomic, nullable, copy)   NSArray<ZBFlairRichtext *> *authorFlairRichtext;
@property (nonatomic, nullable, strong) ZBGildings *gildings;
@property (nonatomic, nullable, copy)   id contentCategories;
@property (nonatomic, nullable, strong) NSNumber *isSelf;
@property (nonatomic, nullable, copy)   id modNote;
@property (nonatomic, nullable, strong) NSNumber *created;
@property (nonatomic, nullable, assign) ZBAuthorFlairType *linkFlairType;
@property (nonatomic, nullable, strong) NSNumber *wls;
@property (nonatomic, nullable, copy)   id bannedBy;
@property (nonatomic, nullable, assign) ZBAuthorFlairType *authorFlairType;
@property (nonatomic, nullable, copy)   NSString *domain;
@property (nonatomic, nullable, strong) NSNumber *allowLiveComments;
@property (nonatomic, nullable, copy)   NSString *selftextHTML;
@property (nonatomic, nullable, strong) NSNumber *likes;
@property (nonatomic, nullable, copy)   NSString *suggestedSort;
@property (nonatomic, nullable, copy)   id bannedAtUTC;
@property (nonatomic, nullable, copy)   id viewCount;
@property (nonatomic, nullable, strong) NSNumber *archived;
@property (nonatomic, nullable, strong) NSNumber *noFollow;
@property (nonatomic, nullable, strong) NSNumber *isCrosspostable;
@property (nonatomic, nullable, strong) NSNumber *pinned;
@property (nonatomic, nullable, strong) NSNumber *over18;
@property (nonatomic, nullable, copy)   NSArray<ZBAllAwarding *> *allAwardings;
@property (nonatomic, nullable, strong) NSNumber *mediaOnly;
@property (nonatomic, nullable, copy)   NSString *linkFlairTemplateID;
@property (nonatomic, nullable, strong) NSNumber *canGild;
@property (nonatomic, nullable, strong) NSNumber *spoiler;
@property (nonatomic, nullable, strong) NSNumber *locked;
@property (nonatomic, nullable, copy)   NSString *authorFlairText;
@property (nonatomic, nullable, strong) NSNumber *visited;
@property (nonatomic, nullable, copy)   id numReports;
@property (nonatomic, nullable, copy)   id distinguished;
@property (nonatomic, nullable, assign) ZBSubredditID *subredditID;
@property (nonatomic, nullable, copy)   id modReasonBy;
@property (nonatomic, nullable, copy)   id removalReason;
@property (nonatomic, nullable, assign) ZBLinkFlairBackgroundColor *linkFlairBackgroundColor;
@property (nonatomic, nullable, copy)   NSString *identifier;
@property (nonatomic, nullable, strong) NSNumber *isRobotIndexable;
@property (nonatomic, nullable, copy)   id reportReasons;
@property (nonatomic, nullable, copy)   NSString *author;
@property (nonatomic, nullable, strong) NSNumber *numCrossposts;
@property (nonatomic, nullable, strong) NSNumber *numComments;
@property (nonatomic, nullable, strong) NSNumber *sendReplies;
@property (nonatomic, nullable, assign) ZBWhitelistStatus *whitelistStatus;
@property (nonatomic, nullable, strong) NSNumber *contestMode;
@property (nonatomic, nullable, copy)   NSArray *modReports;
@property (nonatomic, nullable, strong) NSNumber *authorPatreonFlair;
@property (nonatomic, nullable, assign) ZBFlairTextColor *authorFlairTextColor;
@property (nonatomic, nullable, copy)   NSString *permalink;
@property (nonatomic, nullable, assign) ZBWhitelistStatus *parentWhitelistStatus;
@property (nonatomic, nullable, strong) NSNumber *stickied;
@property (nonatomic, nullable, copy)   NSString *url;
@property (nonatomic, nullable, strong) NSNumber *subredditSubscribers;
@property (nonatomic, nullable, strong) NSNumber *createdUTC;
@property (nonatomic, nullable, copy)   id discussionType;
@property (nonatomic, nullable, strong) ZBMedia *media;
@property (nonatomic, nullable, strong) NSNumber *isVideo;
@property (nonatomic, nullable, copy)   NSString *postHint;
@property (nonatomic, nullable, strong) ZBPreview *preview;
@property (nonatomic, nullable, copy)   NSDictionary<NSString *, ZBMediaMetadatum *> *mediaMetadata;
@end

@interface ZBAllAwarding : NSObject
@property (nonatomic, nullable, strong) NSNumber *isEnabled;
@property (nonatomic, nullable, strong) NSNumber *count;
@property (nonatomic, nullable, copy)   id subredditID;
@property (nonatomic, nullable, copy)   NSString *theDescription;
@property (nonatomic, nullable, strong) NSNumber *coinReward;
@property (nonatomic, nullable, strong) NSNumber *iconWidth;
@property (nonatomic, nullable, copy)   NSString *iconURL;
@property (nonatomic, nullable, strong) NSNumber *daysOfPremium;
@property (nonatomic, nullable, copy)   NSString *identifier;
@property (nonatomic, nullable, strong) NSNumber *iconHeight;
@property (nonatomic, nullable, copy)   NSArray<ZBResizedIcon *> *resizedIcons;
@property (nonatomic, nullable, strong) NSNumber *daysOfDripExtension;
@property (nonatomic, nullable, copy)   NSString *awardType;
@property (nonatomic, nullable, strong) NSNumber *coinPrice;
@property (nonatomic, nullable, strong) NSNumber *subredditCoinReward;
@property (nonatomic, nullable, copy)   NSString *name;
@end

@interface ZBResizedIcon : NSObject
@property (nonatomic, nullable, copy)   NSString *url;
@property (nonatomic, nullable, strong) NSNumber *width;
@property (nonatomic, nullable, strong) NSNumber *height;
@end

@interface ZBFlairRichtext : NSObject
@property (nonatomic, nullable, assign) ZBAuthorFlairType *e;
@property (nonatomic, nullable, copy)   NSString *t;
@end

@interface ZBGildings : NSObject
@property (nonatomic, nullable, strong) NSNumber *gid1;
@property (nonatomic, nullable, strong) NSNumber *gid2;
@property (nonatomic, nullable, strong) NSNumber *gid3;
@end

@interface ZBMedia : NSObject
@property (nonatomic, nullable, strong) ZBRedditVideo *redditVideo;
@property (nonatomic, nullable, strong) ZBOembed *oembed;
@property (nonatomic, nullable, copy)   NSString *type;
@end

@interface ZBOembed : NSObject
@property (nonatomic, nullable, copy)   NSString *providerURL;
@property (nonatomic, nullable, copy)   NSString *url;
@property (nonatomic, nullable, copy)   NSString *html;
@property (nonatomic, nullable, copy)   NSString *authorName;
@property (nonatomic, nullable, copy)   id height;
@property (nonatomic, nullable, strong) NSNumber *width;
@property (nonatomic, nullable, copy)   NSString *version;
@property (nonatomic, nullable, copy)   NSString *authorURL;
@property (nonatomic, nullable, copy)   NSString *providerName;
@property (nonatomic, nullable, strong) NSNumber *cacheAge;
@property (nonatomic, nullable, copy)   NSString *type;
@end

@interface ZBRedditVideo : NSObject
@property (nonatomic, nullable, copy)   NSString *fallbackURL;
@property (nonatomic, nullable, strong) NSNumber *height;
@property (nonatomic, nullable, strong) NSNumber *width;
@property (nonatomic, nullable, copy)   NSString *scrubberMediaURL;
@property (nonatomic, nullable, copy)   NSString *dashURL;
@property (nonatomic, nullable, strong) NSNumber *duration;
@property (nonatomic, nullable, copy)   NSString *hlsURL;
@property (nonatomic, nullable, strong) NSNumber *isGIF;
@property (nonatomic, nullable, copy)   NSString *transcodingStatus;
@end

@interface ZBMediaEmbed : NSObject
@property (nonatomic, nullable, copy)   NSString *content;
@property (nonatomic, nullable, strong) NSNumber *width;
@property (nonatomic, nullable, strong) NSNumber *scrolling;
@property (nonatomic, nullable, strong) NSNumber *height;
@property (nonatomic, nullable, copy)   NSString *mediaDomainURL;
@end

@interface ZBMediaMetadatum : NSObject
@property (nonatomic, nullable, assign) ZBStatus *status;
@property (nonatomic, nullable, assign) ZBE *e;
@property (nonatomic, nullable, strong) ZBS *s;
@property (nonatomic, nullable, assign) ZBM *m;
@property (nonatomic, nullable, copy)   NSString *identifier;
@end

@interface ZBS : NSObject
@property (nonatomic, nullable, strong) NSNumber *y;
@property (nonatomic, nullable, strong) NSNumber *x;
@property (nonatomic, nullable, copy)   NSString *u;
@end

@interface ZBPreview : NSObject
@property (nonatomic, nullable, copy)   NSArray<ZBImage *> *images;
@property (nonatomic, nullable, strong) NSNumber *enabled;
@end

@interface ZBImage : NSObject
@property (nonatomic, nullable, strong) ZBResizedIcon *source;
@property (nonatomic, nullable, copy)   NSArray<ZBResizedIcon *> *resolutions;
@property (nonatomic, nullable, strong) ZBVariants *variants;
@property (nonatomic, nullable, copy)   NSString *identifier;
@end

@interface ZBVariants : NSObject
@end

NS_ASSUME_NONNULL_END
