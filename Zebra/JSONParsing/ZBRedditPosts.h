// To parse this JSON:
//
//   NSError *error = NULL;
//   ZBRedditPosts *redditPosts = [ZBRedditPosts fromJSON:json encoding:NSUTF8Encoding error:&error];

#import <Foundation/Foundation.h>

@class ZBRedditPost;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Object interfaces

@interface ZBRedditPosts : NSObject
+ (nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error;
@property (nonatomic, nullable, strong) NSArray <ZBRedditPost *> *data;
@end

@interface ZBRedditPost : NSObject
@property (nonatomic, nullable, strong) NSString *title;
@property (nonatomic, nullable, strong) NSString *url;
@property (nonatomic, nullable, strong) NSString *thumbnail;
@property (nonatomic, nullable, strong) NSString *tags;
@end

NS_ASSUME_NONNULL_END
