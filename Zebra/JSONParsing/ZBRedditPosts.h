// To parse this JSON:
//
//   NSError *error = NULL;
//   ZBRedditPosts *redditPosts = [ZBRedditPosts fromJSON:json encoding:NSUTF8Encoding error:&error];

#import <Foundation/Foundation.h>

@class ZBRedditPosts;
@class ZBRedditPostsData;
@class ZBChild;
@class ZBChildData;
@class ZBResizedIcon;
@class ZBPreview;
@class ZBImage;
@class ZBMediaMetadatum;
@class ZBMediaSource;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Object interfaces

@interface ZBRedditPosts : NSObject
@property (nonatomic, nullable, strong) ZBRedditPostsData *data;

+ (_Nullable instancetype)fromJSON:(NSString *)json encoding:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
+ (_Nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error;
- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
- (NSData *_Nullable)toData:(NSError *_Nullable *)error;
@end

@interface ZBRedditPostsData : NSObject
@property (nonatomic, nullable, copy)   NSArray<ZBChild *> *children;
@end

@interface ZBChild : NSObject
@property (nonatomic, nullable, strong) ZBChildData *data;
@end

@interface ZBChildData : NSObject
@property (nonatomic, nullable, copy)   NSString *identifier;
@property (nonatomic, nullable, strong) NSNumber *created;
@property (nonatomic, nullable, copy)   NSString *title;
@property (nonatomic, nullable, copy)   NSString *linkFlairCSSClass;
@property (nonatomic, nullable, copy)   NSString *url;
@property (nonatomic, nullable, copy)   NSString *thumbnail;
@property (nonatomic, nullable, strong) ZBPreview *preview;
@property (nonatomic, nullable, copy)   NSDictionary <NSString *, ZBMediaMetadatum *> *mediaMetadata;
@end

@interface ZBResizedIcon : NSObject
@property (nonatomic, nullable, copy)   NSString *url;
@property (nonatomic, nullable, strong) NSNumber *width;
@property (nonatomic, nullable, strong) NSNumber *height;
@end

@interface ZBPreview : NSObject
@property (nonatomic, nullable, copy)   NSArray<ZBImage *> *images;
@end

@interface ZBImage : NSObject
@property (nonatomic, nullable, strong) ZBResizedIcon *source;
@end

@interface ZBMediaMetadatum : NSObject
@property (nonatomic, nullable, copy)   NSString *type;
@property (nonatomic, nullable, strong) ZBMediaSource *source;
@end

@interface ZBMediaSource : NSObject
@property (nonatomic, nullable, copy)   NSString *url;
@property (nonatomic, nullable, strong) NSNumber *width;
@property (nonatomic, nullable, strong) NSNumber *height;
@end

NS_ASSUME_NONNULL_END
